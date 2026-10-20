# Requirements — Music Widget Oblivion

## 1. Product Goal
Build a macOS menu bar widget that provides quick playback controls and context for Apple Music/Spotify, with UX optimized for fast output switching (AirPlay-oriented use cases).

## 2. Scope

### In Scope (MVP)
- Menu bar app with compact now-playing status.
- Dropdown panel with:
  - Current track metadata (title, artist, album).
  - Playback controls (previous, play/pause, next).
  - Progress display.
  - Output selector entry point that opens macOS Sound settings for AirPlay/audio output selection.
- Source selection (Apple Music / Spotify) with graceful fallback.
- Basic playlist quick-access section.
- Basic error and permission handling UX.

### Out of Scope (MVP)
- Full queue management editing.
- Advanced recommendations/discovery.
- Cross-device sync beyond player-native behavior.

## 3. Personas
- **Power listener on macOS**: Needs instant control without opening full player windows.
- **Multi-output user**: Frequently switches between local speakers, headphones, and AirPlay devices.

## 4. User Stories (MVP)
1. As a user, I can see what is currently playing from the menu bar.
2. As a user, I can play/pause and skip tracks from the dropdown.
3. As a user, I can quickly access output switching for AirPlay scenarios.
4. As a user, I can switch preferred source between Apple Music and Spotify.
5. As a user, I get clear feedback when permissions are missing or player is unavailable.

## 5. Acceptance Criteria
- Menu bar status updates within acceptable delay after track change.
- Playback controls map correctly to active source.
- Permission-denied states show actionable guidance.
- Output switching entry is discoverable in <= 2 clicks from menu bar icon.
- Selecting a playlist from the active provider starts playback, or displays a clear unavailable/error state.
- App remains responsive under temporary source/API failures.

## 6. Non-Functional Requirements
- macOS-native look and feel.
- Fast startup and low idle resource usage.
- Defensive error handling and safe fallbacks.
- Logging that is useful for debugging without exposing sensitive data.

## 7. Definition of Done (DoD)
A feature is done when:
- Acceptance criteria are met.
- Tests are added/updated and passing.
- Docs are updated if behavior changes.
- PR checklist is complete and reviewed.
