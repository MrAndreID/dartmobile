# MrAndreID / DartMobile

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

The `MrAndreID/DartMobile` is a Flutter mobile app skeleton (iOS & Android) built with a feature-first, layered architecture. It ships with a Hello World feature and full User CRUD backed by the [MrAndreID/goapi](https://github.com/MrAndreID/goapi) service (Go + Echo).

## Table of Contents

* [Requirements](#requirements)
* [Installation](#installation)
* [Configuration](#configuration)
* [Running](#running)
* [Unit Test](#unit-test)
* [Usage](#usage)
* [Backend Contract](#backend-contract)
* [Versioning](#versioning)
* [Authors](#authors)
* [Contributing](#contributing)
* [Official Documentation for Flutter](#official-documentation-for-flutter)
* [License](#license)

## Requirements

To use The `MrAndreID/DartMobile`, you must ensure that you meet the following requirements:
- [Flutter](https://flutter.dev/) >= 3.22.0
- [Dart](https://dart.dev/) >= 3.4.0 < 4.0.0
- A running instance of the [MrAndreID/goapi](https://github.com/MrAndreID/goapi) service

## Installation

To use The `MrAndreID/DartMobile`, you must follow the steps below:
- Clone a Repository
```git
# git clone https://github.com/MrAndreID/DartMobile.git
```
- Create .env file from .env.example (Linux/macOS)
```sh
# cp .env.example .env
```
- Configuring .env file (see [Configuration](#configuration))
- (Re)generate platform boilerplate and fetch dependencies. `flutter create` only fills in missing files, so it is safe to run on an existing project.
```sh
# flutter create --org com.mrandreid --project-name dart_mobile .
# flutter pub get
```

## Configuration

To configure The `MrAndreID/DartMobile`, set the following values in the `.env` file at the project root:

| Name           | Description                                                        |
| :------------- | :----------------------------------------------------------------- |
| `API_BASE_URL` | Base URL of the goapi service. Android emulator: `http://10.0.2.2:10001`; iOS simulator: `http://127.0.0.1:10001`; physical device: your machine's LAN IP. |
| `API_APP_KEY`  | Application key sent as the `X-App-Key` header. Must match the `APP_KEY` configured in the goapi `.env` file. |

Example `.env`:

```env
API_BASE_URL=http://10.0.2.2:10001
API_APP_KEY=your-goapi-app-key
```

`AppConfig.load()` validates the configuration at startup and fails fast with a `StateError` when `API_APP_KEY` is missing, so a misconfiguration surfaces immediately rather than as opaque 401s later.

## Running

To run The `MrAndreID/DartMobile`, you must ensure that you meet the following requirements:
- Start the goapi backend separately (see its README).
- Run The `MrAndreID/DartMobile`
```sh
# flutter run
```
- Analyze and format the code (optional)
```sh
# flutter analyze
# dart format .
```

### Notes on platform files

- **Android**: `usesCleartextTraffic="true"` is set so the app can reach the local HTTP goapi server. Remove it for production/HTTPS.
- **iOS**: `NSAllowsArbitraryLoads` is enabled in `Info.plist` for the same reason. Tighten it before shipping.

## Unit Test

To run Unit Test for The `MrAndreID/DartMobile`:
```sh
# flutter test
```

## Usage

The project follows a **feature-first** structure with a clean, layered split inside each feature (`domain` -> `data` -> `presentation`). Cross-cutting concerns live under `core/`.

- Directory Structure The `MrAndreID/DartMobile`

| Name                                    | Description                                               |
| :-------------------------------------- | :-------------------------------------------------------- |
| `lib/main.dart`                         | Entry Point: load config, build router, run app.          |
| `lib/app.dart`                          | Root `MaterialApp.router` and theming.                    |
| `lib/core/config`                       | Typed access to `.env` values (`AppConfig`).              |
| `lib/core/error`                        | Domain-level error types (`Failure`).                     |
| `lib/core/network`                      | Dio client, response envelope, and exceptions.            |
| `lib/core/providers`                    | App-wide Riverpod providers (`ApiClient`).                |
| `lib/core/router`                       | `go_router` route configuration.                          |
| `lib/core/theme`                        | Material 3 light/dark themes.                             |
| `lib/features/home`                     | Landing screen listing available features.                |
| `lib/features/hello_world`              | Presentation-only feature.                                |
| `lib/features/user/domain`              | Entities and repository contract (pure Dart).             |
| `lib/features/user/data`                | DTOs, remote data source, repository implementation.      |
| `lib/features/user/presentation`        | Providers, pages, and widgets.                            |
| `test`                                  | Unit and widget tests.                                    |

### Layer responsibilities

| Layer          | Knows about                     | Never knows about         |
| :------------- | :------------------------------ | :------------------------ |
| `domain`       | Entities, repository interfaces | Dio, JSON, Flutter        |
| `data`         | JSON shapes, HTTP, DTOs         | Widgets                   |
| `presentation` | Widgets, Riverpod, domain       | Dio, JSON, response codes |

Data sources throw transport-level `ApiException`s; repositories translate those into domain `Failure`s so the UI deals with a small, stable error set.

### Tech stack

- **flutter_riverpod** - state management & DI
- **dio** - HTTP client
- **go_router** - declarative navigation
- **flutter_dotenv** - environment configuration
- **equatable** - value equality for models/state

## Backend Contract

All user endpoints live under `/api/v1` and require the `X-App-Key` header. Responses use the envelope `{ code, description, data }`.

| Method | Path                | Body / Query               | Result                      |
| :----- | :------------------ | :------------------------- | :-------------------------- |
| GET    | `/api/v1/user`      | `page, limit, search`      | `{records, total, nextPage}` |
| POST   | `/api/v1/user`      | `{ name, emails[] }`       | created `User`              |
| PATCH  | `/api/v1/user/:id`  | `{ name?, emails[]? }`     | success                     |
| DELETE | `/api/v1/user/:id`  | —                          | success                     |

## Versioning

I use [Semantic Versioning](https://semver.org/). For the versions available, see the tags on this repository.

## Authors

- **Andrea Adam** - [MrAndreID](https://github.com/MrAndreID)

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.
Please make sure to update tests as appropriate.

## Official Documentation for Flutter

Documentation for Flutter can be found on the [Flutter website](https://docs.flutter.dev/).

## License

The `MrAndreID/DartMobile` is released under the [MIT License](https://opensource.org/licenses/MIT). See the `LICENSE` file for more information.
