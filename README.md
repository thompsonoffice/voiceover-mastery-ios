# Screen Reader Mastery (repo: voiceover-mastery-ios)

A native SwiftUI iPhone and iPad app (iOS/iPadOS 17+) sold on the App Store as **Screen Reader Mastery**, an offline guide to VoiceOver. The App Store name avoids using the Apple trademark "VoiceOver" as a product name (App Review Guideline 5.2.5). Fully offline. No accounts, ads, tracking, or purchase links.

The chapters are the book's plain text, parsed into sections and bundled as `VoiceOverMastery/Resources/book.json`. The wording is not rewritten. Regenerate that file with `python3 tools/export_book.py` after a chapter edit. CI checks that the JSON matches the chapters.

Planned App Store price: $3.99. Seller: Hunter Thompson. Category: Education. Privacy label: **Data Not Collected**. Signing and TestFlight stay off until the secrets in `docs/APP-STORE-SETUP.md` exist.

## Features

- First launch asks **I use VoiceOver** or **I'm sighted and learning VoiceOver**. Sighted learners get a short orientation (app text, not a chapter) about the Accessibility Shortcut, the Settings path, the fact that gestures change while VoiceOver is on, and leaving Screen Curtain off until it is familiar.
- **Browse** by device: iPhone, iPad, Mac, Apple Watch, Apple TV, and Apple Vision Pro, plus About and Apps and Practice.
- **Chapter reader** with VoiceOver headings for each section: Overview, What you'll learn, the teaching sections, Practice exercise, Quick reference summary, and Sources.
- **Progress**: mark a chapter complete, and resume the last chapter and section.
- **Search** across chapter text and the book's index. Every word must match.
- **Bookmarks**, stored on the device.
- **Quick reference** for each device, built only from the chapters' quick reference bullets.
- **Practice** on iPhone and iPad: a real button, slider, and list, with labels, hints, custom actions, and a Practice rotor. It does not add VoiceOver gestures.
- Dynamic Type, stronger contrast, Reduce Motion, and iPad Split View / Slide Over (size classes, all iPad orientations, not full-screen-only).

## Project layout

- `project.yml`: XcodeGen spec (app, unit tests, UI tests). The generated `.xcodeproj` is not committed.
- `content/VoiceOver-Mastery/`: the plain-text book.
- `VoiceOverMastery/`: SwiftUI sources, `Resources/book.json`, assets, `PrivacyInfo.xcprivacy`.
- `VoiceOverMasteryTests/`: data integrity, exact chapter text, search, quick reference, progress.
- `VoiceOverMasteryUITests/`: flows and `performAccessibilityAudit()`.
- `.github/workflows/ios-ci.yml`: simulator build and tests on a macOS runner.
- `.github/workflows/testflight-upload.yml`: signing and upload, **skipped** until App Store Connect secrets exist.

## Build

```sh
brew install xcodegen
xcodegen generate
```

Open `VoiceOverMastery.xcodeproj` and run the VoiceOverMastery scheme on an iPhone or iPad simulator. Unit tests and UI tests are part of that scheme.

Real-device VoiceOver use, signing, TestFlight, and App Review have not been done. The simulator audit does not replace testing with VoiceOver on an iPhone or iPad.
