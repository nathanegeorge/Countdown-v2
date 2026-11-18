//
//  ConfigurationWindowController.swift
//  Countdown
//
//  Originally created by Sam Soffes on 8/6/15.
//  Rebuilt in code in 2026, so the screen saver builds without Interface Builder.
//

import AppKit

/// The sheet shown from "Options…" in System Settings › Screen Saver.
final class ConfigurationWindowController: NSWindowController {

	private let preferences = Preferences()

	private let titleField: NSTextField = {
		let field = NSTextField(string: "")
		field.placeholderString = "Optional, e.g. “Until launch day”"
		return field
	}()

	private let datePicker: NSDatePicker = {
		let picker = NSDatePicker()
		picker.datePickerStyle = .textFieldAndStepper
		picker.datePickerElements = [.yearMonthDay, .hourMinuteSecond]
		return picker
	}()

	private let finishedField: NSTextField = {
		let field = NSTextField(string: "")
		field.placeholderString = "Leave blank to count up instead"
		return field
	}()

	private let textColorPopUp = NSPopUpButton()
	private let backgroundColorPopUp = NSPopUpButton()
	private let showSecondsCheckbox = NSButton(checkboxWithTitle: "Show seconds", target: nil, action: nil)
	private let driftCheckbox = NSButton(checkboxWithTitle: "Slowly drift to prevent screen burn-in", target: nil, action: nil)


	// MARK: - Initializers

	init() {
		let window = NSWindow(
			contentRect: NSRect(x: 0, y: 0, width: 460, height: 300),
			styleMask: [.titled],
			backing: .buffered,
			defer: true
		)
		window.title = "Countdown"
		window.isReleasedWhenClosed = false
		super.init(window: window)
		buildInterface()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}


	// MARK: - Values

	/// Fills the controls from saved preferences. Called each time the sheet opens,
	/// so Cancel really does throw away unsaved edits.
	func loadValues() {
		titleField.stringValue = preferences.title
		datePicker.dateValue = preferences.date ?? Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
		finishedField.stringValue = preferences.finishedMessage
		select(preferences.textColorHex, in: textColorPopUp, options: Palette.text)
		select(preferences.backgroundColorHex, in: backgroundColorPopUp, options: Palette.background)
		showSecondsCheckbox.state = preferences.showSeconds ? .on : .off
		driftCheckbox.state = preferences.drift ? .on : .off
	}

	private func saveValues() {
		preferences.title = titleField.stringValue
		preferences.date = datePicker.dateValue
		preferences.finishedMessage = finishedField.stringValue
		preferences.textColorHex = Palette.text[max(0, textColorPopUp.indexOfSelectedItem)].hex
		preferences.backgroundColorHex = Palette.background[max(0, backgroundColorPopUp.indexOfSelectedItem)].hex
		preferences.showSeconds = showSecondsCheckbox.state == .on
		preferences.drift = driftCheckbox.state == .on
		preferences.save()
	}


	// MARK: - Actions

	@objc private func ok(_ sender: Any?) {
		window?.makeFirstResponder(nil) // commit any text field that is still being edited
		saveValues()
		dismiss()
	}

	@objc private func cancel(_ sender: Any?) {
		dismiss()
	}

	private func dismiss() {
		guard let window else { return }
		if let parent = window.sheetParent {
			parent.endSheet(window)
		} else {
			window.close()
		}
	}


	// MARK: - Interface

	private func buildInterface() {
		guard let contentView = window?.contentView else { return }

		fill(textColorPopUp, with: Palette.text)
		fill(backgroundColorPopUp, with: Palette.background)

		let grid = NSGridView(views: [
			[label("Title:"), titleField],
			[label("Count to:"), datePicker],
			[label("When it’s over, show:"), finishedField],
			[label("Text color:"), textColorPopUp],
			[label("Background:"), backgroundColorPopUp],
			[NSGridCell.emptyContentView, showSecondsCheckbox],
			[NSGridCell.emptyContentView, driftCheckbox]
		])
		grid.translatesAutoresizingMaskIntoConstraints = false
		grid.rowSpacing = 10
		grid.columnSpacing = 8
		grid.rowAlignment = .firstBaseline
		grid.column(at: 0).xPlacement = .trailing
		grid.row(at: 5).topPadding = 4

		let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancel))
		cancelButton.keyEquivalent = "\u{1b}"
		let okButton = NSButton(title: "OK", target: self, action: #selector(ok))
		okButton.keyEquivalent = "\r"

		let buttons = NSStackView(views: [cancelButton, okButton])
		buttons.translatesAutoresizingMaskIntoConstraints = false
		buttons.spacing = 12

		contentView.addSubview(grid)
		contentView.addSubview(buttons)

		NSLayoutConstraint.activate([
			grid.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
			grid.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
			grid.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
			titleField.widthAnchor.constraint(greaterThanOrEqualToConstant: 260),

			buttons.topAnchor.constraint(equalTo: grid.bottomAnchor, constant: 20),
			buttons.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
			buttons.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
			okButton.widthAnchor.constraint(equalTo: cancelButton.widthAnchor),
			okButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 70)
		])
	}

	private func label(_ string: String) -> NSTextField {
		return NSTextField(labelWithString: string)
	}

	/// Adds one menu item per color, each with a small swatch.
	private func fill(_ popUp: NSPopUpButton, with options: [Palette.Option]) {
		popUp.removeAllItems()
		for option in options {
			popUp.addItem(withTitle: option.name)
			popUp.lastItem?.image = swatch(NSColor(hex: option.hex))
		}
	}

	private func select(_ hex: String, in popUp: NSPopUpButton, options: [Palette.Option]) {
		let index = options.firstIndex { $0.hex.caseInsensitiveCompare(hex) == .orderedSame } ?? 0
		popUp.selectItem(at: index)
	}

	private func swatch(_ color: NSColor) -> NSImage {
		return NSImage(size: NSSize(width: 16, height: 12), flipped: false) { rect in
			let path = NSBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), xRadius: 3, yRadius: 3)
			color.setFill()
			path.fill()
			NSColor.gray.withAlphaComponent(0.6).setStroke()
			path.lineWidth = 1
			path.stroke()
			return true
		}
	}
}
