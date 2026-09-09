# DartMobile

A Flutter mobile app skeleton (iOS & Android) built with a feature-first,
layered architecture. It ships with two features:

- **Hello World** — a presentation-only screen demonstrating the module layout.
- **Users** — full CRUD backed by the [MrAndreID/goapi](https://github.com/MrAndreID/goapi)
  service (Go + Echo).

## Architecture

The project follows a **feature-first** structure with a clean, layered split
inside each feature (`domain` → `data` → `presentation`). Cross-cutting
concerns live under `core/`.

```
lib/
├── main.dart                     # Entry point: load config, build router, run app
├── app.dart                      # Root MaterialApp.router + theming
├── core/                         # Cross-cutting infrastructure
│   ├── config/app_config.dart    # Typed access to .env values
│   ├── error/failure.dart        # Domain-level error types
│   ├── network/                  # Dio client, response envelope, exceptions
│   ├── providers/                # App-wide Riverpod providers (ApiClient)
│   ├── router/app_router.dart    # go_router routes
│   └── theme/app_theme.dart      # Material 3 light/dark themes
└── features/
    ├── home/                     # Landing screen
    ├── hello_world/              # Presentation-only feature
    └── user/                     # User CRUD feature
        ├── domain/               # Entities + repository contract (pure Dart)
        ├── data/                 # DTOs, remote data source, repository impl
        └── presentation/         # Providers, pages, widgets
```

### Layer responsibilities

| Layer          | Knows about                     | Never knows about        |
| -------------- | ------------------------------- | ------------------------ |
| `domain`       | Entities, repository interfaces | Dio, JSON, Flutter       |
| `data`         | JSON shapes, HTTP, DTOs         | Widgets                  |
| `presentation` | Widgets, Riverpod, domain       | Dio, JSON, response codes |

Data sources throw transport-level `ApiException`s; repositories translate
those into domain `Failure`s so the UI deals with a small, stable error set.

### State management

[Riverpod](https://riverpod.dev) is used for dependency injection and state.
`AppConfig` is loaded once at startup and `ApiClient` is a single provider-scoped
instance reused across features.

## Tech stack

- **flutter_riverpod** — state management & DI
- **dio** — HTTP client
- **go_router** — declarative navigation
- **flutter_dotenv** — environment configuration
- **equatable** — value equality for models/state

## Backend contract (goapi)

All user endpoints live under `/api/v1` and require the `X-App-Key` header.
Responses use the envelope `{ code, description, data }`.

| Method | Path                | Body / Query                          | Result             |
| ------ | ------------------- | ------------------------------------- | ------------------ |
| GET    | `/api/v1/user`      | `page, limit, search`                 | `{records,total,nextPage}` |
| POST   | `/api/v1/user`      | `{ name, emails[] }`                  | created `User`     |
| PATCH  | `/api/v1/user/:id`  | `{ name?, emails[]? }`                | success            |
| DELETE | `/api/v1/user/:id`  | —                                     | success            |

## Configuration

Copy or edit the committed `.env` file at the project root:

```env
# Android emulator reaches the host via 10.0.2.2; iOS simulator uses 127.0.0.1.
API_BASE_URL=http://10.0.2.2:10001
API_APP_KEY=your-goapi-app-key
```

`API_APP_KEY` must match the `APP_KEY` configured in the goapi `.env`.

## Running

> This skeleton was authored without a local Flutter SDK. After cloning, run the
> command below once to (re)generate any platform boilerplate and fetch
> dependencies. It is safe: `flutter create` only fills in missing files.

```bash
# From the project root
flutter create --org com.mrandreid --project-name dart_mobile .
flutter pub get

# Start the goapi backend separately (see its README), then:
flutter run            # pick an iOS or Android device/emulator
```

### Notes on platform files

- **Android**: `usesCleartextTraffic="true"` is set so the app can reach the
  local HTTP goapi server. Remove it for production/HTTPS.
- **iOS**: `NSAllowsArbitraryLoads` is enabled in `Info.plist` for the same
  reason. Tighten it before shipping.

## Testing

```bash
flutter test
```
