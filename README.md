# MemoryPressureNotifier

English | [日本語](README.ja.md)

A background app for macOS that watches memory pressure and notifies you when it reaches the warning level.

- Reads `kern.memorystatus_vm_pressure_level` every 5 seconds and notifies you when it rises from normal (1) to warning (2) or higher. It also notifies you when it jumps straight to critical (4).
- Clicking the notification opens Activity Monitor.
- Shows nothing in the Dock or the menu bar.
- Registers itself as a login item on first launch, so it starts automatically when you log in.

## Requirements

- macOS 13 or later
- Swift compiler (Xcode or Command Line Tools)

## Install

```sh
make install
```

Builds `build/MemoryPressureNotifier.app`, copies it to `~/Applications`, and launches it.

On first launch, macOS asks whether MemoryPressureNotifier may send notifications. Click **Allow**. If you missed the prompt or dismissed it, turn on notifications for MemoryPressureNotifier in **System Settings > Notifications**.

## Uninstall

```sh
make uninstall
```

Removes the login item, quits the app, and deletes it from `~/Applications`.

## Logs

If showing a notification or registering the login item fails, the error is written to the log.

```sh
log stream --predicate 'subsystem == "com.github.sonatard.MemoryPressureNotifier"'
```

## Make targets

| Target | Description |
| --- | --- |
| `build` | Builds `build/MemoryPressureNotifier.app` and signs it with an Apple Development certificate (ad-hoc if none is found) |
| `install` | Builds the app, puts it in `~/Applications`, and launches it |
| `uninstall` | Removes the login item, quits the app, and deletes it |
| `test-notification` | Relaunches the installed app and shows a test notification |
| `clean` | Deletes `build/` |

## License

[MIT](LICENSE)
