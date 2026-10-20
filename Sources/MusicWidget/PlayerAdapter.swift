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
    func playPause() throws
    func next() throws
    func previous() throws
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
}

final class AppleMusicAdapter: ScriptPlayerAdapter {
    init() { super.init(name: "Apple Music", bundleID: "com.apple.Music") }
}

final class SpotifyAdapter: ScriptPlayerAdapter {
    init() { super.init(name: "Spotify", bundleID: "com.spotify.client") }
}
