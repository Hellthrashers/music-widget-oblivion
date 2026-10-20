import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let nowPlayingItem = NSMenuItem(title: "Nada reproduciendose", action: nil, keyEquivalent: "")
    private let sourceItem = NSMenuItem()
    private var refreshMenuItems: [NSMenuItem] = []
    private var timer: Timer?

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
        statusItem.button?.title = "♪"

        // Default inicial: 2s si nunca se guardó valor.
        if UserDefaults.standard.object(forKey: refreshIntervalKey) == nil {
            UserDefaults.standard.set(2, forKey: refreshIntervalKey)
        }

        buildMenu()
        refresh()
        configureTimer()
        Log.info("launch", provider: adapter.name)
    }

    private func buildMenu() {
        let menu = NSMenu()
        nowPlayingItem.isEnabled = false
        menu.addItem(nowPlayingItem)
        menu.addItem(.separator())
        menu.addItem(item("⏮ Previous", #selector(previousTapped)))
        menu.addItem(item("⏯ Play/Pause", #selector(playPauseTapped)))
        menu.addItem(item("⏭ Next", #selector(nextTapped)))
        menu.addItem(.separator())

        sourceItem.action = #selector(toggleSource)
        sourceItem.target = self
        updateSourceTitle()
        menu.addItem(sourceItem)

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

    private func item(_ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let i = NSMenuItem(title: title, action: action, keyEquivalent: key)
        i.target = self
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

    @objc private func quit() { NSApplication.shared.terminate(nil) }

    private func refresh() {
        do {
            if let np = try adapter.nowPlaying() {
                let text = "\(np.isPlaying ? "▶" : "⏸") \(np.title) — \(np.artist)"
                nowPlayingItem.title = text
                statusItem.button?.title = text.count > 40 ? String(text.prefix(40)) + "…" : text
            } else {
                nowPlayingItem.title = "Nada reproduciendose (\(adapter.name))"
                statusItem.button?.title = "♪"
            }
        } catch {
            Log.error("refresh", provider: adapter.name, error: "\(error)")
            nowPlayingItem.title = "\(adapter.name): error (revisa permisos de Automation)"
            statusItem.button?.title = "♪"
        }
    }
}
