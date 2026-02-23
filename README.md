# TeslaMate iOS

A native iPhone and iPad app for browsing your self-hosted [TeslaMate](https://github.com/teslamate-org/teslamate) data — live vehicle status, drive history, and charging sessions — right from your pocket.

## What This Repo Contains

This repo ships two things that work together:

1. **A JSON API** (`/api/v1/`) added to the TeslaMate Phoenix backend — authenticated REST endpoints plus a real-time WebSocket channel that streams live vehicle data.
2. **A SwiftUI iOS app** that connects to that API and gives you a fast, native mobile experience alongside the existing web UI and Grafana dashboards.

The API is off by default and opt-in. The iOS app is read-only — it does not write to your database or send commands to your car.

## Features

- **Live vehicle overview** — battery, charge state, location, climate, sentry mode, doors/trunk/frunk, and software version, updated in real time over WebSocket
- **Drive history** — paginated drives with distance, duration, energy used, and route visualization on a map
- **Charge history** — sessions with energy added, cost, SoC progression, and charge curve charts
- **Multi-vehicle support** — switch between cars seamlessly
- **Offline caching** — recently viewed data cached locally via SwiftData so the app works without connectivity
- **Secure auth** — JWT-based authentication with tokens stored in the iOS Keychain

## Setup

### 1. Enable the API

Add these environment variables to your TeslaMate deployment:

```env
ENABLE_API=true
API_AUTH_TOKEN=<a-strong-shared-secret>
```

Restart TeslaMate. Confirm the API is running at `/api/v1/health`.

### 2. Connect the iOS app

Open the app, enter your server URL and the auth token from step 1, and tap Connect.

## Development

### Backend

The server runs in Docker. API source is in `lib/teslamate_web/api/`, tests in `test/teslamate_web/api/`.

```bash
docker compose up
```

### iOS App

Open `ios/TeslaMateApp/TeslaMateApp.xcodeproj` in Xcode 16+. Targets iOS 17.0, no external dependencies.

```bash
cd ios/TeslaMateApp
xcodebuild test \
  -project TeslaMateApp.xcodeproj \
  -scheme TeslaMateApp \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

### CI

GitHub Actions runs both Elixir and iOS tests on every push and PR. See `.github/workflows/devops.yml`.

## Project Structure

```
lib/teslamate_web/api/     # JSON API controllers, auth, WebSocket channel
ios/TeslaMateApp/          # SwiftUI app (Models, Services, ViewModels, Views)
test/teslamate_web/api/    # Elixir API tests
ios/.../TeslaMateAppTests/ # iOS unit tests
```

## License

Licensed under the [GNU Affero General Public License v3.0](LICENSE). Based on [TeslaMate](https://github.com/teslamate-org/teslamate).
