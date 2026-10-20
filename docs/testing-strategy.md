# Testing Strategy — Music Widget Oblivion

## 1. Goals
- Validate core playback behavior across providers.
- Catch regressions in menu bar interactions quickly.
- Keep test suite fast enough for frequent local runs.

## 2. Test Pyramid

### Unit Tests (majority)
Focus on pure/business logic:
- Provider selection/fallback logic.
- State reducers/store transitions.
- Mapping of provider responses to UI view-models.
- Error normalization.

### Integration Tests
Focus on module boundaries:
- Core layer ↔ provider adapter contracts.
- Output routing integration boundaries.
- Persistence read/write behavior.

Use mocks/fakes for external dependencies (Spotify APIs, Apple Music scripting APIs, system interfaces).

### Manual/Smoke Tests (MVP)
- App launches and menu bar item appears.
- Now-playing metadata refresh works.
- Play/pause/next/previous actions work on active source.
- Source switch Apple Music ↔ Spotify.
- Missing permission path shows actionable UI.
- Output switch path is reachable and updates state.

## 3. Coverage Guidance
- Prefer meaningful scenario coverage over blanket percentages.
- Critical logic paths should have direct tests before merge.

## 4. CI Expectations
At minimum on each PR:
- Lint
- Type check (if applicable)
- Unit tests

Optional on-demand:
- Integration tests

## 5. Test Data & Fixtures
- Keep fixtures minimal and representative.
- Avoid real credentials/tokens in tests.
- Version fixture schemas when contracts change.

## 6. Regression Policy
Every bug fix should include:
1. A failing test reproducing the bug (where practical).
2. Fix implementation.
3. Passing test proving resolution.
