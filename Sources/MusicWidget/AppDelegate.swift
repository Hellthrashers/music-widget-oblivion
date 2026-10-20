import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let nowPlayingItem = NSMenuItem(title: "Nada reproduciendose", action: nil, keyEquivalent: "")
    private let sourceItem = NSMenuItem()
    private var timer: Timer?

    private let adapters: [PlayerAdapter] = [AppleMusicAdapter(), SpotifyAdapter()]
    private var sourceIndex: Int {
        get { UserDefaults.standard.integer(forKey: "sourceIndex") }
        set { UserDefaults.standard.set(newValue, forKey: "sourceIndex") }
    }
    private var adapter: PlayerAdapter { adapters[sourceIndex % adapters.count] }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "♪"
        buildMenu()
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in self?.refresh() }
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
        menu.addItem(.separator())
        menu.addItem(item("Quit", #selector(quit), key: "q"))
        statusItem.menu = menu
    }

    private func item(_ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let i = NSMenuItem(title: title, action: action, keyEquivalent: key)
        i.target = self
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

    @objc private func previousTapped() { perform("previous") { try adapter.previous() } }
    @objc private func playPauseTapped() { perform("playPause") { try adapter.playPause() } }
    @objc private func nextTapped() { perform("next") { try adapter.next() } }

    @objc private func toggleSource() {
        sourceIndex = (sourceIndex + 1) % adapters.count
        updateSourceTitle()
        Log.info("toggleSource", provider: adapter.name)
        refresh()
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
