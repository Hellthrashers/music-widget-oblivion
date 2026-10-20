# Architecture — Music Widget Oblivion

## 1. Overview
Music Widget Oblivion is a macOS menu bar application that provides quick playback controls and context for Apple Music and Spotify, with fast access to audio output switching (AirPlay-oriented UX).

## 2. Architectural Goals
- Keep UI responsive and lightweight.
- Isolate provider-specific logic (Apple Music / Spotify).
- Fail gracefully when permissions or providers are unavailable.
- Enable incremental feature delivery with testable modules.

## 3. High-Level Components

1. **Menu Bar UI Layer**
   - Renders status item and dropdown panel.
   - Displays now-playing info, controls, playlists shortcuts, and output entry point.
   - Dispatches user intents to application services.

2. **Application/Core Layer**
   - Coordinates state and use-cases:
     - Get current playback state
     - Control playback
     - Switch active provider
     - Refresh data
   - Applies fallback rules and conflict resolution.

3. **Provider Adapters**
   - `AppleMusicAdapter`
   - `SpotifyAdapter`
   - Common interface:
     - `getNowPlaying()`
     - `playPause()`
     - `nextTrack()`
     - `previousTrack()`
     - `getPlaylists()`
   - Handles provider auth/permission specifics behind interface boundary.

4. **Output Routing Layer**
   - Integrates with macOS output/AirPlay mechanisms.
   - Exposes discover/select operations to UI.
   - Provides safe fallback when requested output is unavailable.

5. **Persistence & Preferences**
   - Stores selected provider, UI preferences, and last known lightweight state.
   - No sensitive token logging.
   - Prefer Keychain for secrets if needed.

6. **Observability**
   - Structured logs with context (provider, action, result, error class).
   - Error surfaces mapped to user-friendly messages.

## 4. Suggested Directory Structure

```text
src/
  app/
    usecases/
    state/
  ui/
    menubar/
    dropdown/
    components/
  providers/
    apple-music/
    spotify/
    types/
  output/
  persistence/
  diagnostics/
  shared/
```

## 5. Data Flow (Typical Control Action)
1. User clicks `Play/Pause` in dropdown.
2. UI dispatches intent to Core use-case.
3. Core resolves active provider.
4. Provider adapter executes action.
5. Result propagates back to Core state.
6. UI re-renders and log event is emitted.

## 6. Error-Handling Strategy
- Provider unavailable → show non-blocking warning + retry option.
- Missing permission → show actionable CTA to System Settings.
- Network/API failures → bounded retries for reads, no aggressive retries for controls.
- Unknown errors → generic message + diagnostic log entry.

## 7. Performance Notes
- Polling/refresh intervals should be conservative and adaptive.
- Avoid expensive operations on menu-open path.
- Cache last now-playing snapshot for immediate paint.

## 8. Security & Privacy
- Store credentials/tokens securely (Keychain).
- Never log secrets, tokens, or personal playlist names unless explicitly opted in for debug.
- Minimize retained user data.

## 9. ADRs (Architecture Decision Records)
Create ADRs under `docs/adr/` for key decisions:
- Provider abstraction contract
- Output routing strategy
- State management approach
- Refresh/polling strategy
