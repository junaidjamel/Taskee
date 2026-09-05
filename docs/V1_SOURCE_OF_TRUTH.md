# Resource Memory V1 — Source of Truth

## Core action
Save a useful coding resource, understand why it matters, and resurface it when the user starts relevant work.

## V1 user flow
1. User saves a URL or screenshot.
2. App extracts title, source/creator, summary, topics, technologies, and a `useWhen` trigger.
3. Resource is stored in the library.
4. User creates a project with a short description.
5. App ranks saved resources against the project description.
6. App shows: `You already saved these.`

## V1 screens
- Home
- Save Resource
- Resource Library
- Resource Detail
- Project Match
- Settings/Profile

## V1 data objects
- Resource
- Project

Creator, skill, and topic information are stored as metadata in V1. They do not get separate product areas yet.

## V1 non-goals
Do not build courses, an IDE, a social network, a knowledge graph, complex folders, gamification, creator following, or a project-management suite.

## Product rule
Every feature must make it easier to capture useful knowledge or bring that knowledge back when the user needs it.

## Reuse policy
Taskee provides the Flutter foundation, navigation/state/local-storage patterns, and notification plumbing. Other Junaid Jamel repositories may be used as references or sources only after their license and implementation fit are checked. The product behavior in this document remains authoritative.
