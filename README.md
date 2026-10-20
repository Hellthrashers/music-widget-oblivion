# music-widget-oblivion
Menu bar widget for Apple Music/Spotify with quick controls, playlists, and AirPlay-oriented UX on macOS.

## What is this?
`music-widget-oblivion` is a lightweight macOS menu bar app that lets you:
- See **Now Playing** quickly from the menu bar
- Control playback (**previous / play-pause / next**)
- Switch source between **Apple Music** and **Spotify**
- Use basic console logs for troubleshooting

## Requirements
- macOS 12+
- Xcode 15+ (or Swift 5.9 toolchain)
- Apple Music app and/or Spotify app installed

## Installation / Build
Clone the repository:

```bash
git clone https://github.com/Hellthrashers/music-widget-oblivion.git
cd music-widget-oblivion
```

Build with Swift Package Manager:

```bash
swift build
```

## Run
Run directly with SwiftPM:

```bash
swift run
```

Or open in Xcode and run the executable target **MusicWidget**.

## First-run permissions (IMPORTANT)
This app controls Music/Spotify via AppleScript automation.
On first control action, macOS may ask permissions.

If controls do not work:
1. Open **System Settings**
2. Go to **Privacy & Security**
3. Open **Automation**
4. Allow this app (or your terminal/Xcode process) to control:
   - **Music**
   - **Spotify**

You may also need to relaunch the app after granting permissions.

## How to use
1. Launch the app.
2. A menu bar item appears (`♪` or current track text).
3. Click the menu bar item to open controls:
   - `⏮ Previous`
   - `⏯ Play/Pause`
   - `⏭ Next`
4. Click `Source: ...` to toggle active provider:
   - Apple Music
   - Spotify
5. The app refreshes now-playing status automatically.

## Behavior notes
- If selected source app is not running, now-playing may show as unavailable.
- If playback is stopped, menubar shows the fallback icon/text.
- Source selection is persisted locally using `UserDefaults`.

## Logging
The app emits simple logs to console in this style:

```text
[timestamp] action=<action> provider=<provider> result=<ok|error>
```

Useful to debug permission/provider availability issues.

## Troubleshooting
### Controls do nothing
- Verify Automation permissions (see section above).
- Ensure Apple Music or Spotify is running.
- Try switching source and retrying.

### Shows “provider not available”
- The selected provider app is closed or not accessible.
- Open the app manually and retry.

### Build fails
- Check Swift/Xcode version compatibility (Swift 5.9, Xcode 15+).

## Project structure (current MVP)
- `Package.swift` — Swift package definition
- `Sources/MusicWidget/main.swift` — app bootstrap
- `Sources/MusicWidget/AppDelegate.swift` — menu bar UI + actions
- `Sources/MusicWidget/PlayerAdapter.swift` — provider abstraction + AppleScript adapters
- `Sources/MusicWidget/Logger.swift` — basic structured console logging

## License
See [LICENSE](LICENSE).
