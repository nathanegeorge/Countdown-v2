//
//  PlaceView.swift
//  Countdown
//
//  Originally created by Sam Soffes on 3/21/16.
//

import AppKit

/// One column of the countdown: a big number with a small unit label under it.
final class PlaceView: NSView {

	let textLabel = Label()
	let detailTextLabel = Label()

	init(unit: String) {
		super.init(frame: .zero)
		translatesAutoresizingMaskIntoConstraints = false
		detailTextLabel.stringValue = unit

		// The number decides the column width; never squeeze it to fit the unit label.
		textLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
		detailTextLabel.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)

		addSubview(textLabel)
		addSubview(detailTextLabel)

		NSLayoutConstraint.activate([
			textLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
			textLabel.topAnchor.constraint(equalTo: topAnchor),
			textLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
			textLabel.bottomAnchor.constraint(equalTo: detailTextLabel.topAnchor),
			detailTextLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
			detailTextLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
			detailTextLabel.trailingAnchor.constraint(equalTo: trailingAnchor)
		])
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	/// Sets the number, only touching the label when it actually changes.
	func setValue(_ value: Int) {
		let string = String(format: "%02d", value)
		if textLabel.stringValue != string {
			textLabel.stringValue = string
		}
	}

	func setColor(_ color: NSColor) {
		textLabel.textColor = color
		detailTextLabel.textColor = color.withAlphaComponent(0.5)
	}
}
