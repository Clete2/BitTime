# Contributing to BitTime

Thanks for your interest in contributing!

## Setup

```bash
brew install xcodegen
git clone https://github.com/clete2/BitTime.git
cd BitTime
xcodegen generate
open BitTime.xcodeproj
```

The `.xcodeproj` is generated, not committed. If you change `project.yml`,
re-run `xcodegen generate`.

## Branching

- Base your work on `master`.
- Use feature branches: `feat/short-description`, `fix/short-description`.

## Commit messages

This project uses [Conventional Commits](https://www.conventionalcommits.org/)
to drive automated releases. Use one of:

| Type        | Effect on release             |
|-------------|-------------------------------|
| `feat:`     | minor version bump            |
| `fix:`      | patch version bump            |
| `feat!:` or `BREAKING CHANGE:` footer | major version bump |
| `docs:`, `chore:`, `refactor:`, `test:`, `ci:`, `build:`, `style:`, `perf:` | no release |

Examples:

```
feat: add ISO 8601 widget
fix: handle nil status item button when display sleeps
feat!: drop macOS 12 support
```

## Tests

Add tests for new behavior. Run the suite locally:

```bash
xcodebuild -scheme BitTime -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO test
```

CI runs the same command on every PR.

## Pull requests

1. Fork and create a branch.
2. Make focused, self-contained commits.
3. Ensure `xcodebuild test` passes locally.
4. Open a PR against `master` with a description of *why*, not just *what*.
5. The maintainer may squash on merge — keep the PR title in Conventional
   Commit form so the squash commit triggers the right release.

## Code style

- Foundation imports first, then SwiftUI/AppKit, then `BitTimeCore`.
- `public` only for cross-module API.
- Prefer `[weak self]` in long-lived closures.
- Wrap platform-specific code with `#if canImport(...)`.
- Keep comments minimal; prefer self-documenting names.

## License

By contributing, you agree that your contributions will be licensed under the
[Apache License 2.0](LICENSE).
