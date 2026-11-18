# Countdown

A macOS screen saver that counts down to any date. If the date has passed, it counts up from it, or shows a message of your choice.

This is a 2026 port of [soffes/Countdown](https://github.com/soffes/Countdown) 0.1.0. The original was written in Swift 2.2 in 2016 and no longer builds. It also ran only on Intel Macs.

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

Your date from 0.1.0 carries over because the bundle ID and settings key are unchanged.

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
