//
//  CountdownView.swift
//  Countdown
//
//  Originally created by Sam Soffes on 8/6/15.
//  Ported to modern Swift in 2026.
//

import AppKit
import ScreenSaver

final class CountdownView: ScreenSaverView {

	// MARK: - Views

	private let titleLabel = Label()

	/// Shows either the "set your date" hint or the finished message.
	private let messageLabel = Label()

	private let daysView = PlaceView(unit: "DAYS")
	private let hoursView = PlaceView(unit: "HOURS")
	private let minutesView = PlaceView(unit: "MINUTES")
	private let secondsView = PlaceView(unit: "SECONDS")
	private var placeViews: [PlaceView] { [daysView, hoursView, minutesView, secondsView] }

	private let placesView: NSStackView = {
		let view = NSStackView()
		view.translatesAutoresizingMaskIntoConstraints = false
		view.orientation = .horizontal
		view.alignment = .top
		return view
	}()

	/// Title, numbers and message stacked vertically. Hidden views take up no space.
	private let contentView: NSStackView = {
		let view = NSStackView()
		view.translatesAutoresizingMaskIntoConstraints = false
		view.orientation = .vertical
		view.alignment = .centerX
		return view
	}()

	private var centerXConstraint: NSLayoutConstraint?
	private var centerYConstraint: NSLayoutConstraint?

	private lazy var configurationWindowController = ConfigurationWindowController()


	// MARK: - State

	private enum Mode: Equatable {
		case needsDate
		case counting
		case finished
	}

	private let preferences = Preferences()
	private var date: Date?
	private var finishedMessage = ""
	private var showSeconds = true
	private var drift = true
	private var backgroundColor: NSColor = .black
	private var mode: Mode?
	private let startTime = Date()


	// MARK: - Initializers

	override init?(frame: NSRect, isPreview: Bool) {
		super.init(frame: frame, isPreview: isPreview)
		initialize()
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		initialize()
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
		DistributedNotificationCenter.default().removeObserver(self)
	}


	// MARK: - NSView

	override func draw(_ rect: NSRect) {
		backgroundColor.setFill()
		bounds.fill()
	}

	override func setFrameSize(_ newSize: NSSize) {
		super.setFrameSize(newSize)
		updateFonts()
	}


	// MARK: - ScreenSaverView

	override func animateOneFrame() {
		updateContent()
		updateDrift()
	}

	override var hasConfigureSheet: Bool {
		return true
	}

	override var configureSheet: NSWindow? {
		configurationWindowController.loadValues()
		return configurationWindowController.window
	}


	// MARK: - Setup

	private func initialize() {
		// Show the full title and message unless they are wider than the screen.
		titleLabel.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
		messageLabel.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)

		placeViews.forEach(placesView.addArrangedSubview)
		contentView.addArrangedSubview(titleLabel)
		contentView.addArrangedSubview(placesView)
		contentView.addArrangedSubview(messageLabel)
		addSubview(contentView)

		let centerX = contentView.centerXAnchor.constraint(equalTo: centerXAnchor)
		let centerY = contentView.centerYAnchor.constraint(equalTo: centerYAnchor)
		NSLayoutConstraint.activate([
			centerX,
			centerY,
			// Leaves room for the drift (up to 4% each way), so a long title never slides off screen.
			contentView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.9)
		])
		centerXConstraint = centerX
		centerYConstraint = centerY

		loadPreferences()

		NotificationCenter.default.addObserver(self, selector: #selector(preferencesDidChange), name: Preferences.didChangeNotification, object: nil)

		// Since macOS Sonoma, the system host process often keeps screen savers running
		// after you wake the Mac, so instances pile up and waste memory and CPU. Quitting
		// when the screen saver stops is the standard workaround. The preview in System
		// Settings is left alone.
		if !isPreview {
			DistributedNotificationCenter.default().addObserver(self, selector: #selector(screenSaverWillStop), name: Notification.Name("com.apple.screensaver.willstop"), object: nil)
		}
	}

	private func loadPreferences() {
		date = preferences.date
		finishedMessage = preferences.finishedMessage.trimmingCharacters(in: .whitespacesAndNewlines)
		showSeconds = preferences.showSeconds
		drift = preferences.drift
		backgroundColor = NSColor(hex: preferences.backgroundColorHex)

		let title = preferences.title.trimmingCharacters(in: .whitespacesAndNewlines)
		titleLabel.stringValue = title
		titleLabel.isHidden = title.isEmpty

		let textColor = NSColor(hex: preferences.textColorHex)
		titleLabel.textColor = textColor.withAlphaComponent(0.8)
		messageLabel.textColor = textColor
		placeViews.forEach { $0.setColor(textColor) }
		secondsView.isHidden = !showSeconds

		// The numbers change once a second, so there is no need to redraw 30 times a
		// second like version 0.1.0 did. Drifting needs a few frames a second to look smooth.
		animationTimeInterval = drift ? 1.0 / 15 : 0.25

		if !drift {
			centerXConstraint?.constant = 0
			centerYConstraint?.constant = 0
		}

		mode = nil
		updateContent()
		needsDisplay = true
	}

	@objc private func preferencesDidChange(_ notification: Notification) {
		loadPreferences()
	}

	@objc private func screenSaverWillStop(_ notification: Notification) {
		exit(0)
	}


	// MARK: - Updating

	private func updateContent() {
		guard let date else {
			setMode(.needsDate)
			return
		}

		// Whole seconds, so the countdown reaches 00 exactly at the chosen time.
		let now = Date(timeIntervalSince1970: floor(Date().timeIntervalSince1970))
		let hasPassed = now >= date

		if hasPassed && !finishedMessage.isEmpty {
			setMode(.finished)
			return
		}

		setMode(.counting)

		// If the date has passed (and there is no finished message), count up from it.
		var (start, end) = hasPassed ? (date, now) : (now, date)

		// Without seconds, round a countdown up to the next whole minute. Otherwise the
		// whole last minute would read 00 00 00, as if the countdown were already over.
		if !showSeconds && !hasPassed {
			let minutesLeft = ceil(date.timeIntervalSince(now) / 60)
			start = date.addingTimeInterval(-minutesLeft * 60)
			end = date
		}

		let components = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: start, to: end)
		daysView.setValue(abs(components.day ?? 0))
		hoursView.setValue(abs(components.hour ?? 0))
		minutesView.setValue(abs(components.minute ?? 0))
		secondsView.setValue(abs(components.second ?? 0))
	}

	private func setMode(_ newMode: Mode) {
		guard newMode != mode else { return }
		mode = newMode

		placesView.isHidden = newMode != .counting
		messageLabel.isHidden = newMode == .counting

		switch newMode {
		case .needsDate:
			messageLabel.stringValue = "Open Screen Saver Options to set your date."
		case .finished:
			messageLabel.stringValue = finishedMessage
		case .counting:
			break
		}

		updateFonts()
	}

	/// Moves the content along a slow, wandering path so nothing sits in one place for long.
	private func updateDrift() {
		guard drift else { return }

		// Both offsets are 0 when the screen saver starts, so the content begins exactly
		// centered and eases away from there instead of jumping on the first frame.
		let elapsed = Date().timeIntervalSince(startTime)
		let x = sin(elapsed * 2 * .pi / 97) * bounds.width * 0.04
		let y = sin(elapsed * 2 * .pi / 71) * bounds.height * 0.05
		centerXConstraint?.constant = x
		centerYConstraint?.constant = y
	}

	/// Sizes all text relative to the screen width.
	private func updateFonts() {
		let width = bounds.width
		guard width > 0 else { return }

		// With seconds hidden there are only three columns, so they can be bigger.
		let numberSize = round(width / (showSeconds ? 8 : 6.5))
		let numberFont = NSFont.monospacedDigitSystemFont(ofSize: max(4, numberSize), weight: .ultraLight)
		let unitFont = NSFont.systemFont(ofSize: max(4, floor(width / 38)), weight: .thin)

		for place in placeViews {
			place.textLabel.font = numberFont
			place.detailTextLabel.font = unitFont
		}

		placesView.spacing = floor(width * 0.05)
		contentView.spacing = floor(width * 0.02)
		titleLabel.font = NSFont.systemFont(ofSize: max(4, floor(width / 22)), weight: .light)

		let messageSize = mode == .finished ? width / 14 : width / 30
		messageLabel.font = NSFont.systemFont(ofSize: max(4, floor(messageSize)), weight: mode == .finished ? .ultraLight : .thin)
	}
}
