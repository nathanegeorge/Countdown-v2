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

	/// Widest the title and message may be, in points; longer text ends in "…". Set from the
	/// screen width in `updateFonts`. A fixed number rather than a share of this view's width,
	/// because Auto Layout would satisfy a share by making the view itself wider.
	private lazy var textWidthCaps = [titleLabel, messageLabel].map { $0.widthAnchor.constraint(lessThanOrEqualToConstant: 10_000) }

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
	private var drift = false
	private var backgroundColor: NSColor = .black
	private var mode: Mode?

	/// When drifting started. Reset each time drift turns on, so it eases out from the center.
	private var driftStart = Date()

	/// The widest any line of text may be, as a share of the screen width. The rest is room
	/// for the drift (up to 4% each way).
	private let maxTextWidthFraction: CGFloat = 0.9

	/// How many digits the day count has. When it changes (999 → 1000), the numbers
	/// are re-measured so they still fit on screen.
	private var dayDigits = 0


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
		placeViews.forEach(placesView.addArrangedSubview)
		contentView.addArrangedSubview(titleLabel)
		contentView.addArrangedSubview(placesView)
		contentView.addArrangedSubview(messageLabel)
		addSubview(contentView)

		let centerX = contentView.centerXAnchor.constraint(equalTo: centerXAnchor)
		let centerY = contentView.centerYAnchor.constraint(equalTo: centerYAnchor)
		NSLayoutConstraint.activate([centerX, centerY] + textWidthCaps)
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
		if preferences.drift && !drift {
			driftStart = Date()
		}
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
		dayDigits = 0
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
		let days = abs(components.day ?? 0)
		daysView.setValue(days)
		hoursView.setValue(abs(components.hour ?? 0))
		minutesView.setValue(abs(components.minute ?? 0))
		secondsView.setValue(abs(components.second ?? 0))

		let digits = max(2, String(days).count)
		if digits != dayDigits {
			dayDigits = digits
			updateFonts()
		}
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

		// Both offsets are 0 when drifting starts, so the content begins exactly centered
		// and eases away from there instead of jumping.
		let elapsed = Date().timeIntervalSince(driftStart)
		let x = sin(elapsed * 2 * .pi / 97) * bounds.width * 0.04
		let y = sin(elapsed * 2 * .pi / 71) * bounds.height * 0.05
		centerXConstraint?.constant = x
		centerYConstraint?.constant = y
	}

	/// Sizes all text relative to the screen.
	private func updateFonts() {
		guard bounds.width > 0, bounds.height > 0 else { return }

		// Sizes follow the screen width, except on very wide screens (wider than 2:1, such
		// as 32:9 ultra-wides), where width-based text would be taller than the screen.
		let width = min(bounds.width, bounds.height * 2)
		let maxTextWidth = bounds.width * maxTextWidthFraction
		textWidthCaps.forEach { $0.constant = maxTextWidth }

		// With seconds hidden there are only three columns, so they can be bigger.
		let numberSize = round(width / (showSeconds ? 8 : 6.5))
		applyPlaceSizes(number: numberSize, unit: floor(width / 38), spacing: floor(width * 0.05))

		// A long day count (1000+ days) makes the row wider. If it no longer fits in the
		// space left after drifting, shrink the whole row by just enough to fit.
		let rowWidth = placesView.fittingSize.width
		if rowWidth > maxTextWidth {
			let scale = maxTextWidth / rowWidth
			applyPlaceSizes(number: floor(numberSize * scale), unit: floor(width / 38 * scale), spacing: floor(width * 0.05 * scale))
		}

		contentView.spacing = floor(width * 0.02)
		titleLabel.font = fittingFont(for: titleLabel, size: width / 22, weight: .light, maxWidth: maxTextWidth)

		let isFinished = mode == .finished
		messageLabel.font = fittingFont(for: messageLabel, size: width / (isFinished ? 14 : 30), weight: isFinished ? .ultraLight : .thin, maxWidth: maxTextWidth)
	}

	/// The system font at `size`, shrunk (down to half) so the label's text fits in
	/// `maxWidth`. Text still too long after that is cut off with "…".
	private func fittingFont(for label: Label, size: CGFloat, weight: NSFont.Weight, maxWidth: CGFloat) -> NSFont {
		var pointSize = max(4, floor(size))
		let smallest = max(4, floor(size / 2))
		while true {
			let font = NSFont.systemFont(ofSize: pointSize, weight: weight)
			label.font = font
			if label.intrinsicContentSize.width <= maxWidth || pointSize <= smallest {
				return font
			}
			pointSize = max(smallest, floor(pointSize * 0.95))
		}
	}

	private func applyPlaceSizes(number: CGFloat, unit: CGFloat, spacing: CGFloat) {
		let numberFont = NSFont.monospacedDigitSystemFont(ofSize: max(4, number), weight: .ultraLight)
		let unitFont = NSFont.systemFont(ofSize: max(4, unit), weight: .thin)
		for place in placeViews {
			place.textLabel.font = numberFont
			place.detailTextLabel.font = unitFont
		}
		placesView.spacing = spacing
	}
}
