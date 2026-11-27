//
//  main.swift (check tool)
//  Runs the screen saver through layout and timing cases and fails if anything is cut
//  off, off screen or wrong. Run with `./build.sh check`.
//

import AppKit
import ScreenSaver

_ = NSApplication.shared
var failures = 0

func expect(_ ok: Bool, _ name: String, _ detail: String) {
	print("\(ok ? "PASS" : "FAIL")  \(name)  (\(detail))")
	if !ok { failures += 1 }
}

func child<T>(_ view: CountdownView, _ name: String) -> T {
	return Mirror(reflecting: view).children.first { $0.label == name }!.value as! T
}

/// A view with the given settings, after its first frame.
func makeView(width: CGFloat, height: CGFloat, configure: (Preferences) -> Void) -> CountdownView {
	let preferences = Preferences()
	preferences.date = Date().addingTimeInterval(12 * 86_400 + 3_723)
	preferences.title = ""
	preferences.finishedMessage = ""
	preferences.showSeconds = true
	preferences.drift = false
	configure(preferences)
	preferences.save()
	let view = CountdownView(frame: NSRect(x: 0, y: 0, width: width, height: height), isPreview: true)!
	view.animateOneFrame()
	view.layoutSubtreeIfNeeded()
	return view
}

/// Everything on screen, and no number squeezed narrower than its text.
func checkLayout(_ name: String, width: CGFloat = 1440, height: CGFloat = 900, configure: (Preferences) -> Void) {
	let view = makeView(width: width, height: height, configure: configure)
	let content: NSView = child(view, "contentView")
	let frame = content.frame
	let onScreen = view.bounds.insetBy(dx: -0.5, dy: -0.5).contains(frame)

	var squeezed: [String] = []
	for name in ["daysView", "hoursView", "minutesView", "secondsView"] {
		let place: PlaceView = child(view, name)
		let label = place.textLabel
		if !place.isHidden && label.frame.width + 0.5 < ceil(label.attributedStringValue.size().width) {
			squeezed.append(name)
		}
	}

	let detail = "content x \(Int(frame.minX))–\(Int(frame.maxX)), y \(Int(frame.minY))–\(Int(frame.maxY)) on \(Int(width))×\(Int(height))"
		+ (squeezed.isEmpty ? "" : ", cut off: \(squeezed.joined(separator: ", "))")
	expect(onScreen && squeezed.isEmpty, name, detail)
}

let longText = "Happy New Year! See you all at the party tonight"

checkLayout("short countdown") { _ in }
checkLayout("1,501 days") { $0.date = Date().addingTimeInterval(1_501 * 86_400) }
checkLayout("99,999 days, no seconds") { $0.date = Date().addingTimeInterval(99_999 * 86_400); $0.showSeconds = false }
checkLayout("long title") { $0.title = "Until the big family reunion up in the mountains next summer" }
checkLayout("long finished message") { $0.date = Date().addingTimeInterval(-60); $0.title = "Launch"; $0.finishedMessage = longText }
checkLayout("32:9 ultra-wide, no seconds, title", width: 5_120, height: 1_440) { $0.showSeconds = false; $0.title = "Launch" }
checkLayout("System Settings thumbnail", width: 296, height: 168) { $0.title = "Launch" }

// Turning drift on in a view that is already running should start from the center.
do {
	let view = makeView(width: 1440, height: 900) { _ in }
	Thread.sleep(forTimeInterval: 2)
	let preferences = Preferences()
	preferences.drift = true
	preferences.save()
	view.animateOneFrame()
	let x = (child(view, "centerXConstraint") as NSLayoutConstraint?)?.constant ?? 0
	let y = (child(view, "centerYConstraint") as NSLayoutConstraint?)?.constant ?? 0
	expect(abs(x) < 2 && abs(y) < 2, "drift turned on while running", "first offset x \(Int(x)), y \(Int(y))")
}

// Leave the check tool's own settings empty again.
ScreenSaverDefaults(forModuleWithName: "com.samsoffes.countdown.snapshot")?.removePersistentDomain(forName: "com.samsoffes.countdown.snapshot")
_ = try? Process.run(URL(fileURLWithPath: "/usr/bin/defaults"), arguments: ["-currentHost", "delete", "com.samsoffes.countdown.snapshot"])

print(failures == 0 ? "All checks passed." : "\(failures) check(s) failed.")
exit(failures == 0 ? 0 : 1)
