import AppKit

private struct PlaylistSelection {
    let sourceIndex: Int
    let playlistIndex: Int
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let nowPlayingItem = NSMenuItem(title: "Nada reproduciendose", action: nil, keyEquivalent: "")
    private let sourceItem = NSMenuItem()
    private let playlistsMenu = NSMenu(title: "Playlists")
    private var refreshMenuItems: [NSMenuItem] = []
    private var timer: Timer?
    private var artworkTrackKey: String?
    private var currentArtwork: NSImage?

    private let adapters: [PlayerAdapter] = [AppleMusicAdapter(), SpotifyAdapter()]

    private let sourceIndexKey = "sourceIndex"
    private let refreshIntervalKey = "refreshInterval"

    private var sourceIndex: Int {
        get {
            let raw = UserDefaults.standard.integer(forKey: sourceIndexKey)
            return raw % adapters.count
        }
        set { UserDefaults.standard.set(newValue, forKey: sourceIndexKey) }
    }

    /// nil = Manual (sin timer)
    private var refreshInterval: TimeInterval? {
        get {
            let value = UserDefaults.standard.double(forKey: refreshIntervalKey)
            if value <= 0 { return nil }
            return value
        }
        set {
            UserDefaults.standard.set(newValue ?? 0, forKey: refreshIntervalKey)
            configureTimer()
            updateRefreshMenuChecks()
            Log.info("setRefreshInterval", provider: adapter.name)
        }
    }

    private var adapter: PlayerAdapter { adapters[sourceIndex] }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        setStatusTitle("♪")

        // Default inicial: 2s si nunca se guardó valor.
        if UserDefaults.standard.object(forKey: refreshIntervalKey) == nil {
            UserDefaults.standard.set(2, forKey: refreshIntervalKey)
        }

        buildMenu()
        DispatchQueue.main.async { [weak self] in self?.refresh() }
        configureTimer()
        Log.info("launch", provider: adapter.name)
    }

    private func setStatusTitle(_ title: String) {
        guard let button = statusItem.button, button.title != title else { return }
        button.title = title
    }

    private func buildMenu() {
        let menu = NSMenu()
        nowPlayingItem.isEnabled = false
        menu.addItem(nowPlayingItem)
        menu.addItem(.separator())
        menu.addItem(item("⏮ Previous", #selector(previousTapped), key: "b", modifiers: [.command, .option]))
        menu.addItem(item("⏯ Play/Pause", #selector(playPauseTapped), key: "k", modifiers: [.command, .option]))
        menu.addItem(item("⏭ Next", #selector(nextTapped), key: "n", modifiers: [.command, .option]))
        menu.addItem(.separator())

        sourceItem.action = #selector(toggleSource)
        sourceItem.target = self
        updateSourceTitle()
        menu.addItem(sourceItem)

        let playlistsItem = NSMenuItem(title: "Playlists", action: nil, keyEquivalent: "")
        playlistsMenu.delegate = self
        playlistsItem.submenu = playlistsMenu
        menu.addItem(playlistsItem)

        menu.addItem(item("Open Sound Settings…", #selector(openSoundSettings)))

        let refreshSubmenuItem = NSMenuItem(title: "Refresh Interval", action: nil, keyEquivalent: "")
        let refreshSubmenu = NSMenu(title: "Refresh Interval")
        refreshSubmenuItem.submenu = refreshSubmenu

        refreshMenuItems = [
            refreshIntervalItem(title: "Manual", interval: nil),
            refreshIntervalItem(title: "2s", interval: 2),
            refreshIntervalItem(title: "5s", interval: 5),
            refreshIntervalItem(title: "10s", interval: 10),
            refreshIntervalItem(title: "15s", interval: 15)
        ]

        refreshMenuItems.forEach { refreshSubmenu.addItem($0) }
        menu.addItem(refreshSubmenuItem)
        updateRefreshMenuChecks()

        menu.addItem(.separator())
        menu.addItem(item("Refresh now", #selector(forceRefresh)))
        menu.addItem(item("Quit", #selector(quit), key: "q"))
        statusItem.menu = menu
    }

    private func item(
        _ title: String,
        _ action: Selector,
        key: String = "",
        modifiers: NSEvent.ModifierFlags = .command
    ) -> NSMenuItem {
        let i = NSMenuItem(title: title, action: action, keyEquivalent: key)
        i.target = self
        i.keyEquivalentModifierMask = modifiers
        return i
    }

    private func refreshIntervalItem(title: String, interval: TimeInterval?) -> NSMenuItem {
        let i = NSMenuItem(title: title, action: #selector(changeRefreshInterval(_:)), keyEquivalent: "")
        i.target = self
        i.representedObject = interval as NSNumber?
        return i
    }

    private func updateSourceTitle() {
        sourceItem.title = "Source: \(adapter.name) (click para cambiar)"
    }

    private func progressText(for nowPlaying: NowPlaying) -> String? {
        guard let elapsedTime = nowPlaying.elapsedTime,
              let duration = nowPlaying.duration,
              duration > 0 else { return nil }

        func format(_ time: TimeInterval) -> String {
            let seconds = max(0, Int(time))
            return "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
        }

        return "\(format(elapsedTime)) / \(format(duration))"
    }

    private func perform(_ action: String, _ block: () throws -> Void) {
        do {
            try block()
            Log.info(action, provider: adapter.name)
        } catch {
            Log.error(action, provider: adapter.name, error: "\(error)")
            nowPlayingItem.title = "\(adapter.name) no disponible"
        }
        refresh()
    }

    private func configureTimer() {
        timer?.invalidate()
        timer = nil

        guard let interval = refreshInterval else {
            Log.info("timerDisabled", provider: adapter.name)
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        Log.info("timerConfigured", provider: adapter.name)
    }

    private func updateRefreshMenuChecks() {
        let current = refreshInterval
        for item in refreshMenuItems {
            let represented = (item.representedObject as? NSNumber)?.doubleValue
            let representedInterval: TimeInterval? = represented
            if current == nil && representedInterval == nil {
                item.state = .on
            } else if let current, let representedInterval, current == representedInterval {
                item.state = .on
            } else {
                item.state = .off
            }
        }
    }

    @objc private func changeRefreshInterval(_ sender: NSMenuItem) {
        if let value = (sender.representedObject as? NSNumber)?.doubleValue {
            refreshInterval = value
        } else {
            refreshInterval = nil
        }
    }

    @objc private func previousTapped() { perform("previous") { try adapter.previous() } }
    @objc private func playPauseTapped() { perform("playPause") { try adapter.playPause() } }
    @objc private func nextTapped() { perform("next") { try adapter.next() } }

    @objc private func toggleSource() {
        sourceIndex = (sourceIndex + 1) % adapters.count
        updateSourceTitle()
        Log.info("toggleSource", provider: adapter.name)
        refresh()
    }

    @objc private func forceRefresh() {
        refresh()
        Log.info("forceRefresh", provider: adapter.name)
    }

    @objc private func openSoundSettings() {
        let soundPane = URL(fileURLWithPath: "/System/Library/PreferencePanes/Sound.prefPane")
        guard NSWorkspace.shared.open(soundPane) else {
            nowPlayingItem.title = "No se pudieron abrir los ajustes de sonido"
            Log.error("openSoundSettings", provider: adapter.name, error: "could not open Sound settings")
            return
        }
        Log.info("openSoundSettings", provider: adapter.name)
    }

    func menuWillOpen(_ menu: NSMenu) {
        guard menu === playlistsMenu else { return }
        playlistsMenu.removeAllItems()
        do {
            let names = try adapter.playlists()
            guard !names.isEmpty else {
                let emptyItem = NSMenuItem(title: "No hay playlists disponibles", action: nil, keyEquivalent: "")
                emptyItem.isEnabled = false
                playlistsMenu.addItem(emptyItem)
                return
            }
            for (index, name) in names.enumerated() {
                let playlistItem = item(name, #selector(playPlaylist(_:)))
                playlistItem.representedObject = PlaylistSelection(
                    sourceIndex: sourceIndex,
                    playlistIndex: index
                )
                playlistsMenu.addItem(playlistItem)
            }
        } catch {
            let errorItem = NSMenuItem(title: "Playlists no disponibles", action: nil, keyEquivalent: "")
            errorItem.isEnabled = false
            playlistsMenu.addItem(errorItem)
            Log.error("loadPlaylists", provider: adapter.name, error: "\(error)")
        }
    }

    @objc private func playPlaylist(_ sender: NSMenuItem) {
        guard let selection = sender.representedObject as? PlaylistSelection else { return }
        let selectedAdapter = adapters[selection.sourceIndex]
        do {
            try selectedAdapter.playPlaylist(at: selection.playlistIndex)
            Log.info("playPlaylist", provider: selectedAdapter.name)
            refresh()
        } catch {
            Log.error("playPlaylist", provider: selectedAdapter.name, error: "\(error)")
            nowPlayingItem.title = "\(selectedAdapter.name): no se pudo reproducir la playlist"
            setStatusTitle("♪")
        }
    }

    @objc private func quit() { NSApplication.shared.terminate(nil) }

    private func refresh() {
        do {
            var activeAdapter = adapter
            var nowPlaying = try activeAdapter.nowPlaying()
            if nowPlaying?.isPlaying != true {
                for (index, candidate) in adapters.enumerated() where index != sourceIndex {
                    if let candidateNowPlaying = try? candidate.nowPlaying(), candidateNowPlaying.isPlaying {
                        sourceIndex = index
                        activeAdapter = candidate
                        nowPlaying = candidateNowPlaying
                        updateSourceTitle()
                        Log.info("autoDetectSource", provider: candidate.name)
                        break
                    }
                }
            }

            if let nowPlaying {
                let trackKey = "\(activeAdapter.name)|\(nowPlaying.title)|\(nowPlaying.artist)"
                if trackKey != artworkTrackKey {
                    artworkTrackKey = trackKey
                    currentArtwork = (try? activeAdapter.artwork()).flatMap { data in
                        guard let image = NSImage(data: data) else { return nil }
                        image.size = NSSize(width: 32, height: 32)
                        return image
                    }
                }
                nowPlayingItem.image = currentArtwork
                let progress = progressText(for: nowPlaying).map { " · \($0)" } ?? ""
                let text = "\(nowPlaying.isPlaying ? "▶" : "⏸") \(nowPlaying.title) — \(nowPlaying.artist)\(progress)"
                nowPlayingItem.title = text
                setStatusTitle(text.count > 40 ? String(text.prefix(40)) + "…" : text)
            } else {
                artworkTrackKey = nil
                currentArtwork = nil
                nowPlayingItem.image = nil
                nowPlayingItem.title = "Nada reproduciendose (\(adapter.name))"
                setStatusTitle("♪")
            }
        } catch {
            Log.error("refresh", provider: adapter.name, error: "\(error)")
            nowPlayingItem.title = "\(adapter.name): error (revisa permisos de Automation)"
            setStatusTitle("♪")
        }
    }
}
