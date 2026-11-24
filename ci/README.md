# CI

The active workflows live in `.github/workflows/`:

- `ios-ci.yml` builds the app for the iOS Simulator and runs unit tests, UI tests, and `performAccessibilityAudit`. It runs on pull requests and on pushes to `main`. It does not sign or upload.
- `testflight-upload.yml` is manual only, and its job is skipped until the repository variable `ENABLE_TESTFLIGHT_UPLOAD` is `true` and the App Store Connect secrets in `docs/APP-STORE-SETUP.md` exist.

UI tests run on an iPhone simulator. The app itself is universal (iPhone and iPad) and adapts with size classes for Split View and Slide Over.
