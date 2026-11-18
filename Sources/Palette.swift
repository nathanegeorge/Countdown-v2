//
//  Palette.swift
//  Countdown
//

import AppKit

/// The colors offered in Screen Saver Options. Add entries here to offer more.
/// (Preset menus are used instead of a color well because the system color panel
/// is unreliable inside the screen saver's options sheet.)
enum Palette {

	struct Option {
		let name: String
		let hex: String
	}

	static let text: [Option] = [
		Option(name: "White", hex: "FFFFFF"),
		Option(name: "Warm White", hex: "FFF1DC"),
		Option(name: "Amber", hex: "FFB000"),
		Option(name: "Coral", hex: "FF7A66"),
		Option(name: "Mint", hex: "7CF5C4"),
		Option(name: "Sky", hex: "7CC8FF"),
		Option(name: "Lavender", hex: "C9A7FF"),
		Option(name: "Soft Gray", hex: "9A9A9A")
	]

	static let background: [Option] = [
		Option(name: "Black", hex: "000000"),
		Option(name: "Charcoal", hex: "1C1C1E"),
		Option(name: "Midnight", hex: "0B1530"),
		Option(name: "Forest", hex: "0E2A1F"),
		Option(name: "Plum", hex: "2A1030"),
		Option(name: "Oxblood", hex: "2E0A0A")
	]
}

extension NSColor {
	/// Creates an sRGB color from a six-digit hex string such as "FFB000".
	convenience init(hex: String) {
		let value = UInt32(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0xFFFFFF
		self.init(
			srgbRed: CGFloat((value >> 16) & 0xFF) / 255,
			green: CGFloat((value >> 8) & 0xFF) / 255,
			blue: CGFloat(value & 0xFF) / 255,
			alpha: 1
		)
	}
}
