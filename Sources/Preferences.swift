//
//  Preferences.swift
//  Countdown
//
//  Originally created by Sam Soffes on 8/6/15.
//  Ported to modern Swift in 2026.
//

import AppKit
import ScreenSaver

/// Settings stored in the screen saver's own defaults domain.
final class Preferences {

	static let didChangeNotification = Notification.Name("Countdown.PreferencesDidChange")

	private enum Key {
		// Same key as version 0.1.0, so a date picked in the old version carries over.
		static let date = "Date2"
		static let title = "Title"
		static let finishedMessage = "FinishedMessage"
		static let textColor = "TextColor"
		static let backgroundColor = "BackgroundColor"
		static let showSeconds = "ShowSeconds"
		static let drift = "Drift"
	}

	private let defaults: UserDefaults

	init() {
		// Outside the .saver bundle (the snapshot tool) use a separate domain, never the real one.
		let identifier = Bundle(for: Preferences.self).bundleIdentifier ?? "com.samsoffes.countdown.snapshot"
		defaults = ScreenSaverDefaults(forModuleWithName: identifier) ?? .standard
		defaults.register(defaults: [
			Key.textColor: Palette.text[0].hex,
			Key.backgroundColor: Palette.background[0].hex,
			Key.showSeconds: true,
			Key.drift: true
		])
	}

	var date: Date? {
		get { (defaults.object(forKey: Key.date) as? Double).map(Date.init(timeIntervalSince1970:)) }
		set {
			if let newValue {
				defaults.set(newValue.timeIntervalSince1970, forKey: Key.date)
			} else {
				defaults.removeObject(forKey: Key.date)
			}
		}
	}

	var title: String {
		get { defaults.string(forKey: Key.title) ?? "" }
		set { defaults.set(newValue, forKey: Key.title) }
	}

	/// Shown once the date has passed. When empty, the screen saver counts up instead.
	var finishedMessage: String {
		get { defaults.string(forKey: Key.finishedMessage) ?? "" }
		set { defaults.set(newValue, forKey: Key.finishedMessage) }
	}

	var textColorHex: String {
		get { defaults.string(forKey: Key.textColor) ?? Palette.text[0].hex }
		set { defaults.set(newValue, forKey: Key.textColor) }
	}

	var backgroundColorHex: String {
		get { defaults.string(forKey: Key.backgroundColor) ?? Palette.background[0].hex }
		set { defaults.set(newValue, forKey: Key.backgroundColor) }
	}

	var showSeconds: Bool {
		get { defaults.bool(forKey: Key.showSeconds) }
		set { defaults.set(newValue, forKey: Key.showSeconds) }
	}

	/// Slowly moves the countdown around the screen to avoid burn-in.
	var drift: Bool {
		get { defaults.bool(forKey: Key.drift) }
		set { defaults.set(newValue, forKey: Key.drift) }
	}

	/// Writes changes to disk and tells any running countdown views to refresh.
	func save() {
		defaults.synchronize()
		NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
	}
}
