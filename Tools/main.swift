//
//  main.swift (snapshot tool)
//  Renders the screen saver and its options sheet to PNG files, so changes can be
//  checked without installing. Run with `./build.sh snapshot`.
//

import AppKit
import ScreenSaver

_ = NSApplication.shared
let outputDirectory = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
let size = NSSize(width: 1440, height: 900)

func write(_ view: NSView, to name: String) {
	view.layoutSubtreeIfNeeded()
	guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
	view.cacheDisplay(in: view.bounds, to: rep)
	let url = URL(fileURLWithPath: outputDirectory).appendingPathComponent("\(name).png")
	try? rep.representation(using: .png, properties: [:])?.write(to: url)
	print("Wrote \(url.path)")
}

func render(_ name: String, configure: (Preferences) -> Void) {
	let preferences = Preferences()
	configure(preferences)
	preferences.save()
	guard let view = CountdownView(frame: NSRect(origin: .zero, size: size), isPreview: true) else { return }
	view.animateOneFrame()
	write(view, to: name)
}

func reset(_ p: Preferences) {
	p.date = nil
	p.title = ""
	p.finishedMessage = ""
	p.textColorHex = Palette.text[0].hex
	p.backgroundColorHex = Palette.background[0].hex
	p.showSeconds = true
	p.drift = false
}

let future = Date().addingTimeInterval(123 * 86_400 + 4 * 3_600 + 5 * 60 + 6)

render("1-no-date") { reset($0) }
render("2-default") { reset($0); $0.date = future }
render("3-title-amber-midnight-no-seconds") {
	reset($0)
	$0.date = future
	$0.title = "Until Launch Day"
	$0.textColorHex = "FFB000"
	$0.backgroundColorHex = "0B1530"
	$0.showSeconds = false
}
render("4-finished") {
	reset($0)
	$0.date = Date().addingTimeInterval(-60)
	$0.title = "Launch Day"
	$0.finishedMessage = "It’s here!"
}
render("5-counting-up") { reset($0); $0.date = Date().addingTimeInterval(-(3 * 86_400 + 90)) }

// The options sheet, filled from the last settings above.
if let view = CountdownView(frame: NSRect(origin: .zero, size: size), isPreview: true),
   let sheet = view.configureSheet,
   let content = sheet.contentView {
	sheet.layoutIfNeeded()
	write(content, to: "6-options-sheet")
}

// Leave the snapshot tool's own settings empty again.
let cleanup = Preferences()
reset(cleanup)
cleanup.save()
