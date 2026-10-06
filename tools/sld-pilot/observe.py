"""Read-only, cross-stack pilot observations. Not an SLD approval engine."""
import argparse
import json
from pathlib import Path, PurePosixPath
import subprocess
import sys


def git(repo, *args):
    result = subprocess.run(
        ['git', '-C', str(repo), *args], capture_output=True, check=False
    )
    if result.returncode:
        # Do not copy stderr: remote URLs or local configuration can be sensitive.
        raise ValueError('Git operation failed; check repository and commit references.')
    return result.stdout


def commit(repo, ref):
    if not ref or ref.startswith('-'):
        raise ValueError('A non-option commit reference is required.')
    return git(repo, 'rev-parse', '--verify', '--end-of-options', ref + '^{commit}').decode().strip()


def inventory(repo, sha):
    records = git(repo, 'ls-tree', '-rz', '--full-tree', sha).split(b'\0')
    files = {}
    for record in records:
        if not record:
            continue
        metadata, path = record.split(b'\t', 1)
        mode, kind, oid = metadata.decode().split()
        files[path.decode('utf-8', errors='surrogateescape')] = {
            'object': oid, 'mode': mode, 'kind': kind
        }
    return files


def snapshot(repo, ref):
    sha = commit(repo, ref)
    files = inventory(repo, sha)
    stack = 'flutter' if 'pubspec.yaml' in files else 'javascript' if 'package.json' in files else 'unknown'
    return {
        'schemaVersion': 1, 'commit': sha, 'stackHint': stack,
        'baselineApproval': 'NOT_RECORDED', 'files': files,
        'scope': 'Committed Git objects only; not a functional or visual baseline.'
    }


def validate_scope(scope):
    if not isinstance(scope, dict) or scope.get('schemaVersion') != 1:
        raise ValueError('Scope schemaVersion must be 1.')
    if not isinstance(scope.get('task'), str) or not scope['task'].strip():
        raise ValueError('Scope needs a task description.')
    if not isinstance(scope.get('paths'), list):
        raise ValueError('Scope paths must be a list of exact relative paths.')
    for path in scope['paths']:
        if not isinstance(path, str) or not path or '\\' in path or path.startswith('/'):
            raise ValueError('Scope paths must be exact relative POSIX paths.')
        if any(part in ('', '.', '..') for part in path.split('/')) or any(c in path for c in '*?['):
            raise ValueError('Globs and path traversal are not allowed in pilot scope.')
        if str(PurePosixPath(path)) != path:
            raise ValueError('Scope path is not normalized.')
    return set(scope['paths'])


def compare(repo, base, head, scope):
    allowed = validate_scope(scope)
    base_sha, head_sha = commit(repo, base), commit(repo, head)
    if base_sha == head_sha:
        raise ValueError('Identical revisions are not evidence of a successful change.')
    before, after = inventory(repo, base_sha), inventory(repo, head_sha)
    changes = []
    for path in sorted(before.keys() | after.keys()):
        old, new = before.get(path), after.get(path)
        if old == new:
            continue
        changes.append({
            'path': path,
            'change': 'add' if old is None else 'delete' if new is None else 'modify',
            'declaredPath': path in allowed,
            'beforeObject': old['object'] if old else None,
            'afterObject': new['object'] if new else None,
        })
    if not changes:
        raise ValueError('No changed Git objects; there is no change to evaluate.')
    outside = sum(not row['declaredPath'] for row in changes)
    dirty = bool(git(repo, 'status', '--porcelain=v1', '-z', '--untracked-files=all'))
    return {
        'schemaVersion': 1, 'task': scope['task'], 'baseCommit': base_sha,
        'headCommit': head_sha, 'observation': 'OUTSIDE_DECLARED_PATHS' if outside else 'PATHS_MATCH_DECLARATION',
        'changedPaths': len(changes), 'outsideDeclaredPaths': outside,
        'workingTreeChangesExcluded': dirty, 'changes': changes,
        'sldDecision': 'NOT_EVALUATED', 'authorization': 'NOT_VERIFIED',
        'functionalChecks': 'NOT_RUN', 'visualChecks': 'NOT_RUN',
        'limitations': [
            'A declared file does not authorize every action or property within it.',
            'Renames appear as deletion plus addition; both paths must be declared.',
            'No dependency graph, semantic review, app execution, or production checks.',
            'Scope is caller-supplied; this report does not establish owner approval.',
            'Uncommitted and ignored files are outside the commit comparison.',
        ],
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('operation', choices=['snapshot', 'compare'])
    parser.add_argument('--repo', required=True, type=Path)
    parser.add_argument('--ref', default='HEAD')
    parser.add_argument('--base')
    parser.add_argument('--head', default='HEAD')
    parser.add_argument('--scope', type=Path)
    args = parser.parse_args()
    try:
        if args.operation == 'snapshot':
            result = snapshot(args.repo, args.ref)
        else:
            if not args.base or not args.scope:
                raise ValueError('Compare requires --base and --scope.')
            result = compare(args.repo, args.base, args.head, json.loads(args.scope.read_text()))
        print(json.dumps(result, indent=2, ensure_ascii=True))
        # Exit zero means observation completed, NOT that SLD approved a release.
        return 1 if result.get('outsideDeclaredPaths', 0) else 0
    except (ValueError, OSError, TypeError) as error:
        print(json.dumps({'observation': 'INSUFFICIENT_EVIDENCE', 'error': str(error)}))
        return 2


if __name__ == '__main__':
    sys.exit(main())
