# Changelog

All notable changes to this project will be documented in this file.

This project follows a lightweight changelog format and uses semantic pre-release tags.

---

## [Unreleased]

### Added
- Playlist quick access for the active Apple Music or Spotify source.
- A menu entry that opens macOS Sound settings for output selection.
- Now-playing artwork in the menu when provided by the active player.
- Playback keyboard shortcuts while the menu is open: `⌥⌘B` previous, `⌥⌘K` play/pause, and `⌥⌘N` next.
- Automatic source selection when playback starts in the other player.

## [v0.1.0-beta.1] - 2026-10-20

### Added
- Initial macOS menu bar app bootstrap (`AppKit` + accessory activation policy).
- Menu item showing now playing info in menu bar.
- Playback controls in menu:
  - Previous
  - Play/Pause
  - Next
- Source toggle between:
  - Apple Music
  - Spotify
- Basic structured console logging for actions and errors.
- README expanded with:
  - Requirements
  - Installation/build
  - Usage
  - macOS Automation permissions
  - Troubleshooting
  - Current MVP structure

### Fixed
- Player app detection now uses **bundle identifiers** instead of localized app names
  (fixes `Music` vs `Música` locale issue on macOS).

### Notes
- Apple Events/Automation permission is required for controlling Music/Spotify.
- If controls fail, check: System Settings → Privacy & Security → Automation.
