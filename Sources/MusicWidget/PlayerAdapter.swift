import Foundation
import AppKit

struct NowPlaying {
    let isPlaying: Bool
    let title: String
    let artist: String
}

enum PlayerError: Error {
    case notRunning
    case script(String)
}

protocol PlayerAdapter {
    var name: String { get }
    func nowPlaying() throws -> NowPlaying?
    func artwork() throws -> Data?
    func playPause() throws
    func next() throws
    func previous() throws
    func playlists() throws -> [String]
    func playPlaylist(at index: Int) throws
}

extension PlayerAdapter {
    func artwork() throws -> Data? { nil }
}

/// Adapter generico basado en AppleScript (Music y Spotify comparten sintaxis).
/// Usa bundle identifier (independiente del idioma del sistema).
class ScriptPlayerAdapter: PlayerAdapter {
    let name: String
    let bundleID: String

    init(name: String, bundleID: String) {
        self.name = name
        self.bundleID = bundleID
    }

    @discardableResult
    func run(_ source: String) throws -> String {
        var errorInfo: NSDictionary?
        guard let script = NSAppleScript(source: source) else {
            throw PlayerError.script("invalid script")
        }
        let result = script.executeAndReturnError(&errorInfo)
        if let errorInfo = errorInfo {
            let msg = (errorInfo[NSAppleScript.errorMessage] as? String) ?? "unknown"
            throw PlayerError.script(msg)
        }
        return result.stringValue ?? ""
    }

    func isRunning() -> Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty
    }

    func nowPlaying() throws -> NowPlaying? {
        guard isRunning() else { return nil }
        let out = try run("""
        tell application id "\(bundleID)"
            if player state is stopped then return "stopped||"
            return (player state as string) & "|" & (name of current track) & "|" & (artist of current track)
        end tell
        """)
        let parts = out.components(separatedBy: "|")
        guard parts.count >= 3, parts[0] != "stopped" else { return nil }
        return NowPlaying(isPlaying: parts[0] == "playing", title: parts[1], artist: parts[2])
    }

    func artwork() throws -> Data? {
        guard isRunning() else { throw PlayerError.notRunning }
        var errorInfo: NSDictionary?
        guard let script = NSAppleScript(source: """
        tell application id "\(bundleID)"
            return data of artwork 1 of current track
        end tell
        """) else {
            throw PlayerError.script("invalid artwork script")
        }
        let result = script.executeAndReturnError(&errorInfo)
        if let errorInfo {
            let message = (errorInfo[NSAppleScript.errorMessage] as? String) ?? "unknown"
            throw PlayerError.script(message)
        }
        return result.data.isEmpty ? nil : result.data
    }

    func playPause() throws {
        guard isRunning() else { throw PlayerError.notRunning }
        try run("tell application id \"\(bundleID)\" to playpause")
    }

    func next() throws {
        guard isRunning() else { throw PlayerError.notRunning }
        try run("tell application id \"\(bundleID)\" to next track")
    }

    func previous() throws {
        guard isRunning() else { throw PlayerError.notRunning }
        try run("tell application id \"\(bundleID)\" to previous track")
    }

    func playlists() throws -> [String] {
        guard isRunning() else { throw PlayerError.notRunning }
        let out = try run("""
        tell application id "\(bundleID)"
            set output to ""
            repeat with playlistItem in (get every playlist)
                set output to output & (name of playlistItem) & (ASCII character 30)
            end repeat
            return output
        end tell
        """)
        return out.split(separator: Character(UnicodeScalar(30)!)).map(String.init)
    }

    func playPlaylist(at index: Int) throws {
        guard isRunning() else { throw PlayerError.notRunning }
        guard index >= 0 else { throw PlayerError.script("invalid playlist index") }
        try run("tell application id \"\(bundleID)\" to play playlist \(index + 1)")
    }
}

final class AppleMusicAdapter: ScriptPlayerAdapter {
    init() { super.init(name: "Apple Music", bundleID: "com.apple.Music") }
}

final class SpotifyAdapter: ScriptPlayerAdapter {
    init() { super.init(name: "Spotify", bundleID: "com.spotify.client") }

    override func playPlaylist(at index: Int) throws {
        guard isRunning() else { throw PlayerError.notRunning }
        guard index >= 0 else { throw PlayerError.script("invalid playlist index") }
        try run("tell application id \"\(bundleID)\" to play track 1 of playlist \(index + 1)")
    }
}
