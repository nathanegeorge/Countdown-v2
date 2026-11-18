# Countdown

A macOS screen saver that counts down to any date. If the date has passed, it counts up from it, or shows a message of your choice.

This is a 2026 port of [soffes/Countdown](https://github.com/soffes/Countdown) 0.1.0. The original was written in Swift 2.2 in 2016 and no longer builds. It also ran only on Intel Macs.

## Installation

**[Download the latest release](https://github.com/nathanegeorge/Countdown-v2/releases/latest).** Unzip it and double-click `Countdown.saver`. Then pick **Countdown** in System Settings › Screen Saver and click **Options…** to set your date.

The screen saver isn't signed with an Apple Developer ID, so the first time you open it macOS says it can't verify the developer. To install it anyway:

1. Click **Done** on the warning. Don't move it to the Trash.
2. Open System Settings › Privacy & Security, scroll down, and click **Open Anyway** next to the message about Countdown.
3. Double-click `Countdown.saver` again.

Or remove the download flag in Terminal, then double-click it again:

```bash
xattr -dr com.apple.quarantine ~/Downloads/Countdown.saver
```

If you're upgrading from 0.1.0, remove the old version from `~/Library/Screen Savers` first. Both versions use the same identifier, so they can't be installed together. If **Options…** doesn't open after upgrading, log out and back in.

## What's new in 0.2.0

- **Modern Swift.** Builds with the current toolchain as a universal binary that runs natively on Apple Silicon and Intel. Requires macOS 13 or later.
- **No Xcode needed.** The options sheet is built in code rather than from a `.xib`, so the Command Line Tools are enough.
- **New options** in System Settings › Screen Saver › Options…:
  - Title above the numbers
  - A message to show when the countdown is over (leave it blank to count up instead)
  - Text color and background color
  - Show or hide seconds (the numbers get bigger without them)
  - Slow drifting to prevent screen burn-in
- **Fixes:**
  - Redraws a few times a second instead of 30, which uses less battery.
  - Quits when the screen saver stops. Since Sonoma, macOS otherwise leaves copies running in the background.
  - Reaches 00 exactly at the chosen time.
  - Long titles and big numbers no longer get cut off.

On Apple Silicon Macs you'll need to set your date again after upgrading from 0.1.0. macOS keeps settings for Intel screen savers (0.1.0 was Intel-only) separate from native ones. On Intel Macs your date carries over.

## Building

```bash
./build.sh            # build/Countdown.saver
./build.sh install    # build, then install into ~/Library/Screen Savers
./build.sh snapshot   # also render sample screenshots into build/snapshots
```

The snapshot tool renders several states and the options sheet to PNG files. It lets you check a design change without installing. It uses its own settings, never your real ones.

## Customizing

| To change… | Edit |
| --- | --- |
| Colors in the menus | `Sources/Palette.swift` |
| Layout, font sizes, drift speed | `Sources/CountdownView.swift` (`updateFonts`, `updateDrift`) |
| The options sheet | `Sources/ConfigurationWindowController.swift` |
| Saved settings | `Sources/Preferences.swift` |

## License

MIT, see `LICENSE`. Original work © 2015 Sam Soffes.
