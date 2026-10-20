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
class ScriptPlayerAdapter: PlayerAdapter {
    let name: String
    let appName: String

    init(name: String, appName: String) {
        self.name = name
        self.appName = appName
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
        NSWorkspace.shared.runningApplications.contains { $0.localizedName == appName }
    }

    func nowPlaying() throws -> NowPlaying? {
        guard isRunning() else { return nil }
        let out = try run("""
        tell application "\(appName)"
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
        try run("tell application \"\(appName)\" to playpause")
    }

    func next() throws {
        guard isRunning() else { throw PlayerError.notRunning }
        try run("tell application \"\(appName)\" to next track")
    }

    func previous() throws {
        guard isRunning() else { throw PlayerError.notRunning }
        try run("tell application \"\(appName)\" to previous track")
    }
}

final class AppleMusicAdapter: ScriptPlayerAdapter {
    init() { super.init(name: "Apple Music", appName: "Music") }
}

final class SpotifyAdapter: ScriptPlayerAdapter {
    init() { super.init(name: "Spotify", appName: "Spotify") }
}
