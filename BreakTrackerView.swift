import ScreenSaver
import AppKit

@objc(BreakTrackerView)
class BreakTrackerView: ScreenSaverView {

    // MARK: - UI
    private var headerLabel:    NSTextField!
    private var startTimeLabel: NSTextField!
    private var elapsedLabel:   NSTextField!
    private var dateLabel:      NSTextField!

    // MARK: - State
    private var startTime: Date?
    private var tickTimer: Timer?

    // MARK: - Constants
    private let startTimePath = "/tmp/break_tracker_start.txt"

    // ──────────────────────────────────────────────────────────────────────
    // MARK: Init
    // ──────────────────────────────────────────────────────────────────────
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        buildUI(isPreview: isPreview)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        buildUI(isPreview: false)
    }

    // ──────────────────────────────────────────────────────────────────────
    // MARK: UI Construction
    // ──────────────────────────────────────────────────────────────────────
    private func buildUI(isPreview: Bool) {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor

        let scale: CGFloat = isPreview ? 0.22 : 1.0

        headerLabel    = makeLabel(size: 18 * scale, color: NSColor(white: 0.45, alpha: 1))
        startTimeLabel = makeLabel(size: 76 * scale, color: .white,
                                   weight: .ultraLight)
        elapsedLabel   = makeLabel(size: 22 * scale, color: NSColor(white: 0.32, alpha: 1))
        dateLabel      = makeLabel(size: 14 * scale, color: NSColor(white: 0.28, alpha: 1))

        headerLabel.stringValue = "☕  break started at"

        for v in [headerLabel, startTimeLabel, elapsedLabel, dateLabel] {
            addSubview(v!)
        }
    }

    private func makeLabel(size: CGFloat,
                           color: NSColor,
                           weight: NSFont.Weight = .regular) -> NSTextField {
        let f = NSTextField(labelWithString: "")
        f.font            = NSFont.systemFont(ofSize: size, weight: weight)
        f.textColor       = color
        f.isBezeled       = false
        f.drawsBackground = false
        f.isEditable      = false
        f.alignment       = .center
        return f
    }

    // ──────────────────────────────────────────────────────────────────────
    // MARK: Layout
    // ──────────────────────────────────────────────────────────────────────
    override func layout() {
        super.layout()
        let w = bounds.width
        let h = bounds.height
        let midY = h * 0.50

        headerLabel.frame    = NSRect(x: 0, y: midY + h * 0.095, width: w, height: h * 0.06)
        startTimeLabel.frame = NSRect(x: 0, y: midY - h * 0.02,  width: w, height: h * 0.14)
        elapsedLabel.frame   = NSRect(x: 0, y: midY - h * 0.095, width: w, height: h * 0.055)
        dateLabel.frame      = NSRect(x: 0, y: midY - h * 0.155, width: w, height: h * 0.045)
    }

    // ──────────────────────────────────────────────────────────────────────
    // MARK: Animation lifecycle
    // ──────────────────────────────────────────────────────────────────────
    override func startAnimation() {
        super.startAnimation()

        // Record start time
        startTime = Date()
        persistStartTime()
        tick()

        // Update every second
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    override func stopAnimation() {
        tickTimer?.invalidate()
        tickTimer = nil
        super.stopAnimation()
    }

    override func animateOneFrame() { /* driven by our own timer */ }

    override var hasConfigureSheet: Bool { false }
    override var configureSheet: NSWindow? { nil }

    // ──────────────────────────────────────────────────────────────────────
    // MARK: Tick
    // ──────────────────────────────────────────────────────────────────────
    private func tick() {
        guard let st = startTime else { return }
        let now = Date()

        // Start time display  e.g. "2:47:30 PM"
        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "h:mm:ss a"
        startTimeLabel.stringValue = timeFmt.string(from: st)

        // Date line  e.g. "Monday, February 23"
        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "EEEE, MMMM d"
        dateLabel.stringValue = dateFmt.string(from: st)

        // Elapsed counter
        let secs = Int(now.timeIntervalSince(st))
        let h = secs / 3600
        let m = (secs % 3600) / 60
        let s = secs % 60
        elapsedLabel.stringValue = h > 0
            ? String(format: "elapsed  %02d:%02d:%02d", h, m, s)
            : String(format: "elapsed  %02d:%02d", m, s)
    }

    // ──────────────────────────────────────────────────────────────────────
    // MARK: Persistence (so the popup daemon can read start time)
    // ──────────────────────────────────────────────────────────────────────
    private func persistStartTime() {
        guard let st = startTime else { return }
        let iso = ISO8601DateFormatter().string(from: st)
        try? iso.write(toFile: startTimePath, atomically: true, encoding: .utf8)
    }
}
