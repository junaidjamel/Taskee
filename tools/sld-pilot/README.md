# SLD pilot observer — Kolmari and Nanynany

First measurement mechanism for the two owner-selected pilots. This is an
advisory, read-only command-line tool, not the finished SLD product, an approval
engine, a safety certification, or a replacement for Kolmari's existing engine.
It uses Python 3 and Git only and works with both Flutter and JavaScript repos.
No app dependencies, production code, CI gates, or customer data are changed.

## Use

Run from this repository, substituting actual checkout paths and commit IDs:

```bash
python3 tools/sld-pilot/observe.py snapshot --repo ../kolmari --ref HEAD
python3 tools/sld-pilot/observe.py snapshot --repo . --ref HEAD
python3 tools/sld-pilot/observe.py compare --repo . --base BASE_SHA --head HEAD_SHA --scope /path/to/scope.json
python3 -m unittest discover -s tools/sld-pilot -p 'test_*.py'
```

Scope input uses exact paths (no wildcards):

```json
{
  "schemaVersion": 1,
  "task": "Describe the specific change being measured",
  "paths": ["lib/features/resource/presentation/pages/save_resource_screen.dart"]
}
```

That example is illustrative, not an approved change. The runner never creates
approval records. Snapshot output contains committed file object IDs and modes,
not contents. Output goes to stdout; store reports privately because filenames
can themselves reveal project information. It makes no network calls.

Compare returns 0 when paths match the supplied declaration, 1 for paths outside
it, and 2 for insufficient input evidence. **Zero is not release approval.**
Same-revision and empty comparisons fail. A dirty worktree is disclosed but not
included; use committed isolated changes for repeatable trials. Renames are
represented by removal and addition, so both paths need declaration. Submodules
are observed only at the recorded pointer; their contents are not inspected.

## Existing work to reuse

- Kolmari has a deterministic core, CLI, task contracts, and tests in `src/sld`.
- Kolmari PR 166 repairs its governance model and is still separate from main
  at inspection. Review and validate it before selecting the shared engine.
- Kolmari PR 171 already contains mobile onboarding work. Its description
  reports a stale demo-access task contract blocking verification. Do not redo
  that feature or treat replacing its contract as owner approval.
- Current Kolmari scanner has no Dart source parsing. The observer covers
  committed file changes in Nanynany, not Dart dependency or behavior semantics.
- Nanynany resource storage, capture, retrieval, commitments, and spoken reminders
  should be mapped to proposed protections and reviewed by the owner. Observing
  files does not establish that those features are working or owner-approved.

## Pilot protocol

1. Record exact starting commits, native builder settings, model, and tool version.
2. Obtain the owner's baseline and task approval separately from implementation.
3. Use isolated copies of the same starting commit for native-tool and SLD trials.
4. Apply the same task and compare against the same declared intended scope.
5. Record task success, unintended changes, correction minutes, elapsed time,
   cost, false blocks, and verification gaps. Leave unmeasured values empty.
6. Run real application checks as well as SLD evaluation. A scoped edit can still
   be broken. Never turn the observer's path match into an SLD ALLOW decision.
7. Repeat trials; report both successes and failures. Two owner projects establish
   feasibility, not market demand or cross-platform support in general.

## Next product milestones

1. Resolve the existing engine PR and test its input integrity against real diffs.
2. Add a project-neutral manifest boundary and a Dart adapter to that shared core.
3. Provide baseline review, task declaration, preview, evidence, and decision UI.
4. Keep necessary dependent changes visible and separately authorized where
   required; preservation must not prevent owner-requested evolution.
5. Add a public demonstration and pilot application after the private loop works.
   Track completed real trials, repeat use, and paid conversions, not just emails.

No waitlist backend, public site, automatic model upgrades, or deployment is
included in this first measurement increment.
