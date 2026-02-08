# Troubleshooting Reference

## Provisioning Errors

### "Communication with Apple failed — Your team has no devices"
Xcode needs a registered physical device to generate provisioning profiles.
1. Plug iPhone in via USB, unlock it, tap "Trust This Computer"
2. Verify device appears: `xcrun xctrace list devices`
3. Select the iPhone as the **build destination** in Xcode's scheme picker **before** setting the team
4. Signing & Capabilities → Try Again on both targets

### "No profiles for bundle ID were found"
Follows from the above — resolve the device registration first, then Try Again.

### "Untrusted Developer"
On device: Settings → General → VPN & Device Management → tap the Apple ID → Trust.

### Free Apple ID Limitations
- Apps expire after 7 days, must re-deploy from Xcode
- Limited to 3 active app IDs
- Paid account ($99/yr) removes these limits

## XcodeGen Entitlements Wipe

`xcodegen generate` overwrites `.entitlements` files with empty dicts. After every regeneration, verify both files contain:

```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.slate.shared</string>
</array>
```

Files to check:
- `Slate/Slate.entitlements`
- `SlateWidget/SlateWidget.entitlements`

Also verify `Slate/Shared/PersistenceConfig.swift` → `appGroupIdentifier` matches.

## Build Errors

### "no exact matches in call to initializer" on SortDescriptor
Use explicit type: `SortDescriptor<TodoItem>(\.field)` instead of `SortDescriptor(\TodoItem.field)`.

### "cannot find type" for new files
New source files aren't in the Xcode project. Run `xcodegen generate` then restore entitlements.

### "cannot find 'UNPresentationOptions' in scope"
Use the async delegate signature instead of the completion handler version:
```swift
func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
    [.banner, .sound]
}
```

## Widget Not Appearing

1. Kill and re-run the app from Xcode (Cmd+R)
2. Home screen → long-press → "+" → search "Slate"
3. If still missing on simulator: `xcrun simctl erase booted` (ask user first — this resets the sim)

## Bundle ID Conflicts on Device

Default `com.slate.app` will collide. When deploying to a real device, update to a unique prefix in:
- `project.yml` → both `PRODUCT_BUNDLE_IDENTIFIER` values
- Both `.entitlements` files → App Group ID
- `PersistenceConfig.swift` → `appGroupIdentifier`
