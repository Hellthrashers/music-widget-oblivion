# Release Process — Music Widget Oblivion

## 1. Versioning
Use Semantic Versioning:
- `MAJOR`: incompatible changes.
- `MINOR`: backward-compatible features.
- `PATCH`: backward-compatible fixes.

## 2. Branching & Merge
- `main` is always releasable.
- Short-lived branches: `feat/*`, `fix/*`, `docs/*`, `chore/*`.
- Merge via PR after checks pass.

## 3. Release Checklist
1. Confirm tests and lint pass.
2. Validate manual smoke checklist on macOS.
3. Update `CHANGELOG.md` (if present).
4. Bump version.
5. Create annotated tag (`vX.Y.Z`).
6. Publish GitHub Release notes.

## 4. Hotfixes
- Branch from latest release tag or `main` as needed.
- Keep scope minimal.
- Ship as patch release.

## 5. Rollback
If release is unstable:
- Revert offending commits on `main`.
- Cut new patch release with clear notes.

## 6. Release Notes Format
Include:
- Highlights
- Fixes
- Breaking changes (if any)
- Migration/upgrade notes (if any)
