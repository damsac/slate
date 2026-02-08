# Slate

A SwiftUI todo app with interactive widgets and lock screen support. iOS 17+.

## Prerequisites

- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- iOS 17+ device or simulator

## Setup

```bash
cd ~/Slate
xcodegen generate
open Slate.xcodeproj
```

## Project Structure

```
Slate/
├── Slate/                  # Main app target
│   ├── SlateApp.swift
│   ├── Models/TodoItem.swift
│   ├── Views/
│   ├── Shared/             # PersistenceConfig, NotificationManager
│   └── Theme/
├── SlateWidget/            # Widget extension target
│   ├── SlateWidget.swift
│   ├── TodoWidgetView.swift
│   ├── TodoTimelineProvider.swift
│   └── ToggleTodoIntent.swift
└── project.yml             # XcodeGen spec
```

## Targets

| Target | Bundle ID | Description |
|--------|-----------|-------------|
| Slate | `com.slate.app` | Main app |
| TodoWidgetExtension | `com.slate.app.widget` | Interactive widget |

Both targets share `TodoItem.swift`, `PersistenceConfig.swift`, and `Theme.swift`.

## App Group

Data is shared between the app and widget via App Group `group.com.slate.shared`. The SQLite store lives at `<group container>/Slate.store`.

## Running on Device

1. Select both targets → Signing & Capabilities → set your development team
2. Change bundle IDs to something unique (e.g. `com.yourname.slate`)
3. Verify the App Group `group.com.slate.shared` is registered under both targets
4. Enable Developer Mode on device: Settings → Privacy & Security → Developer Mode
5. Build and run (Cmd+R)
6. First launch: trust the developer cert at Settings → General → VPN & Device Management

## Adding the Home Screen Widget

1. Run the app at least once
2. Go to home screen → long-press → tap **+** (top-left)
3. Search "Slate" in the widget gallery
4. Add the **medium** widget

If Slate doesn't appear, kill the app, re-run from Xcode (Cmd+R), and try again. Simulator can be stubborn — `xcrun simctl erase booted` resets it fully.

## Adding the Lock Screen Widget

1. Long-press the lock screen → **Customize** → **Lock Screen**
2. Tap a widget slot → search "Slate"
3. **Rectangular** is the only size with interactive buttons — the others are display-only

## Lock Screen Interactions

The rectangular lock screen widget has tappable buttons to check off todos. iOS requires Face ID / Touch ID / passcode before the action executes — you won't land in the app, but you do need to unlock first.

## Notifications

Swipe right on a todo → tap the bell → pick a delay. When the notification arrives, long-press or pull it down → tap **"Mark Done"** to check it off without opening the app.

To test quickly, use the **"In 10 seconds (test)"** option.

## Provisioning Troubleshooting

**"Communication with Apple failed / no devices"**: Xcode needs a physical device connected to generate provisioning profiles. Plug in your iPhone via USB, unlock it, tap "Trust This Computer", then go to Signing & Capabilities → Try Again.

**"Untrusted Developer"**: On the device, go to Settings → General → VPN & Device Management → tap your Apple ID → Trust.

**Free Apple ID limitations**: Apps expire after 7 days and must be re-deployed from Xcode. A paid dev account ($99/yr) removes this.

## Regenerating the Project

After adding/removing source files:

```bash
xcodegen generate
```

**Note:** XcodeGen overwrites entitlements files. After regenerating, verify both `.entitlements` files still contain the App Group key. If not, re-add `com.apple.security.application-groups` → `group.com.slate.shared` in Signing & Capabilities.
