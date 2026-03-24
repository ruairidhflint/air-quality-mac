# Oxygenie

macOS menu bar app that shows **local air quality** (US AQI and pollutants) using the [Open-Meteo Air Quality API](https://open-meteo.com/).

## Requirements

- macOS 14.5+ (Xcode project deployment target)
- Xcode 15+

## Build & run

### Option A — Xcode (easiest)

1. Open `Oxygenie.xcodeproj` in Xcode.
2. Select the **AQI Checker** scheme and **My Mac**.
3. Run (**⌘R**). Xcode builds and launches the app.

The app is an **agent** (`LSUIElement`): no Dock icon; look for the leaf or AQI value in the menu bar.

### Option B — Terminal

- **Build only** (does not start the app): `make build`
- **Build and launch**: `make open` (prints the path and a reminder)

`make build` only compiles; you still need to open `Oxygenie.app` yourself (or use `make open`). The built app lives under Xcode’s **DerivedData** folder; the exact path includes a hash, which is why `make open` asks `xcodebuild` where `BUILT_PRODUCTS_DIR` is.

**After `make open`:** there is still **no Dock icon**. Oxygenie is a **menu bar app** — look at the **top-right of the screen** for the green leaf or the **AQI number** and click it.

### I don’t see it in the menu bar

- **Hidden overflow:** if the menu bar is full, extras move behind the **chevron (`«` / `»`)** next to Control Center. Click that and look for the leaf, **AQI** text, or **…** while loading.
- **Bartender / Ice / similar:** check whether another app is hiding menu bar items.
- **Full screen:** the menu bar can auto-hide; move the pointer to the **top edge** of the screen.
- **Rebuild and relaunch** after updates: `make open` (the app should set itself as an **accessory** app and always show a non‑empty status item).

## Features

- Menu bar **numeric AQI** with color by EPA-style bands
- Popover with pollutants, **health guidance**, **24h trend chart**, last-updated time, refresh
- **Preferences**: AQI alert notifications, **Launch at Login** (SMAppService, macOS 13+)
- Cached last reading for offline / failed network
- Background refresh every 15 minutes when coordinates are known
- Unit tests for AQI categories and JSON decoding

## Tests

**⌘U** in Xcode, or:

```bash
make test
# or
xcodebuild -scheme "AQI Checker" -destination 'platform=macOS' test
```

## Project layout

| Path | Role |
|------|------|
| `air-quality/air_qualityApp.swift` | SwiftUI `App`, `AppDelegate`, menu bar & popover |
| `air-quality/ContentView.swift` | Popover UI & Swift Charts |
| `air-quality/Models/` | API models, errors, `AQICategory` |
| `air-quality/Services/` | Location, network, cache |
| `air-quality/ViewModels/` | `AirQualityViewModel` |
| `air-quality/Views/` | About / preferences |
| `OxygenieTests/` | Unit tests |

## Privacy

Location is used only to request air quality for your coordinates; see usage strings in the target’s generated Info.plist (Xcode build settings). A small marketing site lives in `site/`.

## License

Copyright Rory Flint. All rights reserved.
