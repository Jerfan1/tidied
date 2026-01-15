# tidied

Source code for the **tidied** iOS app, published for transparency.

## Why Open Source?

We claim tidied is 100% private — your photos never leave your device. Don't take our word for it. Read the code.

- ✅ No analytics SDKs
- ✅ No network calls
- ✅ No cloud storage
- ✅ No account required
- ✅ All data stays on your device

## What to Look For

| Folder | What It Does |
|--------|--------------|
| `Services/` | All data stored locally in UserDefaults |
| `PhotoLibraryService.swift` | Only uses Apple's Photos framework |
| `StatsService.swift` | Stats stored on-device only |

## The App

tidied helps you clean your camera roll month-by-month. Swipe left to delete, right to keep. Simple.

<!-- [Download on the App Store](#) -->

## License

Source Available — see [LICENSE](LICENSE)
