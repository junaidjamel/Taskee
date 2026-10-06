import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('observe', Path(__file__).with_name('observe.py'))
observe = importlib.util.module_from_spec(spec)
spec.loader.exec_module(observe)


class ObserverTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.repo = Path(self.temp.name)
        self.git('init', '-q')
        self.git('config', 'user.name', 'Pilot test')
        self.git('config', 'user.email', 'pilot@example.invalid')
        (self.repo / 'pubspec.yaml').write_text('name: fixture\n')
        (self.repo / 'screen.dart').write_text('original\n')
        self.save()
        self.base = observe.commit(self.repo, 'HEAD')

    def git(self, *args):
        return subprocess.run(['git', '-C', str(self.repo), *args], check=True, capture_output=True)

    def save(self):
        self.git('add', '.')
        self.git('commit', '-qm', 'fixture')

    def scope(self, paths):
        return {'schemaVersion': 1, 'task': 'Pilot fixture', 'paths': paths}

    def test_snapshot_has_no_file_contents_and_is_not_approved(self):
        result = observe.snapshot(self.repo, 'HEAD')
        self.assertEqual(result['stackHint'], 'flutter')
        self.assertEqual(result['baselineApproval'], 'NOT_RECORDED')
        self.assertNotIn('original', str(result))

    def test_unrelated_change_detected_even_when_requested_file_changes(self):
        (self.repo / 'screen.dart').write_text('requested\n')
        (self.repo / 'pubspec.yaml').write_text('unrequested\n')
        self.save()
        result = observe.compare(self.repo, self.base, 'HEAD', self.scope(['screen.dart']))
        self.assertEqual(result['outsideDeclaredPaths'], 1)
        self.assertEqual(result['sldDecision'], 'NOT_EVALUATED')

    def test_rename_checks_old_and_new_paths(self):
        (self.repo / 'screen.dart').rename(self.repo / 'new.dart')
        self.save()
        result = observe.compare(self.repo, self.base, 'HEAD', self.scope(['new.dart']))
        self.assertEqual(result['outsideDeclaredPaths'], 1)
        self.assertEqual({c['change'] for c in result['changes']}, {'add', 'delete'})

    def test_identical_and_missing_refs_fail(self):
        for ref in [self.base, 'missing-ref', '--all']:
            with self.assertRaises(ValueError):
                observe.compare(self.repo, self.base, ref, self.scope([]))

    def test_empty_commit_is_not_success(self):
        self.git('commit', '--allow-empty', '-qm', 'empty')
        with self.assertRaises(ValueError):
            observe.compare(self.repo, self.base, 'HEAD', self.scope([]))

    def test_untracked_changes_are_disclosed(self):
        (self.repo / 'screen.dart').write_text('requested\n')
        self.save()
        (self.repo / 'untracked.dart').write_text('not in comparison\n')
        result = observe.compare(self.repo, self.base, 'HEAD', self.scope(['screen.dart']))
        self.assertTrue(result['workingTreeChangesExcluded'])
        self.assertEqual(result['functionalChecks'], 'NOT_RUN')

    def test_invalid_scope_rejected(self):
        for path in ['../screen.dart', '/screen.dart', '**', 'a/./b', 'a//b']:
            with self.assertRaises(ValueError):
                observe.validate_scope(self.scope([path]))

    def test_mode_changes_are_observed(self):
        self.git('update-index', '--chmod=+x', 'screen.dart')
        self.git('commit', '-qm', 'mode')
        result = observe.compare(self.repo, self.base, 'HEAD', self.scope([]))
        self.assertEqual(result['outsideDeclaredPaths'], 1)


if __name__ == '__main__':
    unittest.main()
