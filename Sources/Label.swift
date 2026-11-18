//
//  Label.swift
//  Countdown
//
//  Originally created by Sam Soffes on 3/21/16.
//

import AppKit

/// A non-editable, transparent text field used for all on-screen text.
final class Label: NSTextField {
	init() {
		super.init(frame: .zero)
		translatesAutoresizingMaskIntoConstraints = false
		isEditable = false
		isSelectable = false
		drawsBackground = false
		isBordered = false
		isBezeled = false
		alignment = .center
		lineBreakMode = .byTruncatingTail
	}

	/// At very large, thin font sizes NSTextField reports a width slightly narrower than
	/// the text it draws, which cuts numbers off with "…". Measure the text directly instead.
	override var intrinsicContentSize: NSSize {
		var size = super.intrinsicContentSize
		let textWidth = ceil(attributedStringValue.size().width) + 6
		size.width = max(size.width, textWidth)
		return size
	}

	override var stringValue: String {
		didSet { invalidateIntrinsicContentSize() }
	}

	override var font: NSFont? {
		didSet { invalidateIntrinsicContentSize() }
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
