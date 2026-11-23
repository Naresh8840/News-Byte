# News Byte

A Flutter news application that fetches and displays spaceflight news articles from the [Spaceflight News API](https://api.spaceflightnewsapi.net/v4). Built with clean MVVM architecture, Cubit state management, and a focus on smooth UX including pagination, search, filtering, and swipeable article details.


## Tech Stack

| Technology | Purpose |
|---|---|
| Flutter 3.44.0 | Cross-platform UI framework |
| Dart 3.10 | Programming language |
| FVM | Flutter version management |
| Cubit (flutter_bloc) | State management |
| Dio | HTTP networking |
| MVVM | Architecture pattern |
| Material 3 | Design system |

## Architecture — MVVM

This project follows the **MVVM (Model-View-ViewModel)** pattern to separate business logic from UI concerns. MVVM was chosen because it aligns naturally with Cubit-based state management — each screen has a Cubit (the ViewModel) that owns the state and logic, keeping views purely declarative.

**Data flow:**

```
View (Widget) → ViewModel (Cubit) → Repository → API (Dio) → Spaceflight News API
                     ↓
              State (Equatable)
                     ↓
              View rebuilds via BlocBuilder
```

- **Model** — Data classes (`Article`, `ArticlesResponse`, `Author`) with JSON serialization via `json_serializable`. Equatable is used for value equality in state comparisons.
- **View** — Stateless/Stateful widgets that observe Cubit state through `BlocBuilder` and `BlocListener`. Views contain no business logic.
- **ViewModel** — Cubits (`NewsListCubit`, `NewsDetailCubit`) that manage state transitions, coordinate with repositories, and expose methods the view calls on user interaction.
- **Repository** — `NewsRepository` abstracts API calls behind a clean interface, making Cubits testable with mock repositories.

## State Management — Cubit

Cubit was chosen over full BLoC because the application's interactions are method-call-driven (load, search, filter, paginate) rather than event-stream-driven. Cubit provides the same predictable state flow — `emit()` produces a new immutable state, `BlocBuilder` rebuilds the UI — without the boilerplate of defining event classes. This keeps the codebase lean while retaining testability through `bloc_test`.

Each Cubit defines explicit state classes: `Initial`, `Loading`, `Loaded` (with pagination and filter sub-states), and `Error`. This ensures every UI scenario — shimmer loading, empty results, pagination spinners, error with retry — maps to a concrete, testable state.

## Packages and Dependencies

### Production

| Package | Purpose |
|---|---|
| `flutter_bloc` | Cubit state management with BlocProvider, BlocBuilder, BlocListener |
| `equatable` | Value equality for state classes to prevent unnecessary rebuilds |
| `dio` | HTTP client with interceptors, timeouts, and cancel token support |
| `json_annotation` | Annotations for JSON model serialization |
| `cached_network_image` | Image caching and loading with placeholder support |
| `url_launcher` | Open article URLs in an external browser |
| `shimmer` | Shimmer loading effect for skeleton placeholders |
| `google_fonts` | Nunito Sans font used across the application |
| `intl` | Date formatting for article timestamps |
| `share_plus` | Native share sheet for sharing articles |
| `connectivity_plus` | Network connectivity detection |
| `cupertino_icons` | iOS-style iconography |

## Getting Started

### Prerequisites

- **Flutter SDK 3.44.0** (managed via FVM)
- **Dart SDK 3.10+**
- Android Studio or VS Code with Flutter and Dart plugins
- Android emulator or physical device (Android/iOS)

### FVM Setup

This project uses [FVM (Flutter Version Management)](https://fvm.app/) to pin the Flutter SDK to version **3.44.0**, ensuring all contributors and CI environments use the exact same Flutter version.

**Install FVM:**

```bash
dart pub global activate fvm
```

**Install the project's Flutter version:**

```bash
fvm install
```

**Use the pinned version:**

```bash
fvm use 3.44.0
```

After setup, prefix all Flutter commands with `fvm` (e.g., `fvm flutter run`) to use the pinned SDK version.

### Project Installation

```bash
# Clone the repository
git clone <repository-url>
cd news_byte

# Install the pinned Flutter version
fvm install

# Install dependencies
fvm flutter pub get

# Generate JSON serialization code
fvm dart run build_runner build --delete-conflicting-outputs

# Run the application
fvm flutter run
```

No API keys or environment variables are required. The app uses the public [Spaceflight News API v4](https://api.spaceflightnewsapi.net/v4).

## API Integration and Error Handling

**API Layer:**
- `DioHelper` configures the Dio HTTP client with the base URL, connect/receive timeouts (15s each), and JSON accept headers.
- An error interceptor maps HTTP status codes (400, 403, 404, 429, 500, 502, 503) and network errors (timeout, no connection, cancellation) to `ApiException` with user-friendly messages.
- A log interceptor is enabled in debug mode for request/response inspection.

**Repository Pattern:**
- `NewsRepository` provides methods for fetching articles (with pagination and optional news site filter), searching by title, and fetching a single article by ID.
- Cancel tokens are used to abort in-flight requests when new searches or filter changes are triggered.

**Error Flow:**

```
Dio throws DioException → Interceptor wraps with ApiException
→ Cubit catches and emits error state → View renders ErrorView with retry
```

## Testing

The project includes unit tests for both Cubits using `bloc_test` and `mocktail`.

**What is tested:**

- **NewsListCubit** — loading articles (success and error), pagination with deduplication, pull-to-refresh, search with duplicate query skipping, news site filtering (apply, clear, same-site guard, non-loaded state guard)
- **NewsDetailCubit** — initialization, favourite toggle and untoggle, article list updates, page change with load-more trigger, page count with pagination states
- **Widget test** — app builds without errors

**Run tests:**

```bash
fvm flutter test
```

## Screenshots

<!-- Add screenshots to a screenshots/ directory and update the paths below -->
<!-- Example: -->
<!-- | Light Mode | Dark Mode | -->
<!-- |---|---| -->
<!-- | ![News List](screenshots/news_list_light.png) | ![News List](screenshots/news_list_dark.png) | -->
<!-- | ![News Detail](screenshots/news_detail_light.png) | ![News Detail](screenshots/news_detail_dark.png) | -->

*Screenshots to be added.*

## Key Technical Decisions

| Decision | Rationale |
|---|---|
| **MVVM architecture** | Separates UI, business logic, and data access for testability and maintainability |
| **Cubit over full BLoC** | Method-call-driven interactions don't need event classes; reduces boilerplate while keeping the same state management guarantees |
| **Repository pattern** | Abstracts API calls behind a testable interface, allowing Cubits to be unit tested with mock repositories |
| **FVM** | Pins Flutter SDK to 3.44.0 so every developer and CI environment uses the exact same version |
| **Centralized Dio error handling** | Interceptor maps all HTTP and network errors to `ApiException` with human-readable messages, keeping Cubits clean |
| **CancelToken for search and filter** | Cancels in-flight API requests when the user types a new query or selects a different filter, preventing stale responses |
| **json_serializable** | Compile-time code generation for JSON parsing avoids runtime reflection and catches schema mismatches at build time |

## Build and Run Commands

```bash
# Install dependencies
fvm flutter pub get

# Generate code (JSON serialization)
fvm dart run build_runner build --delete-conflicting-outputs

# Run the app
fvm flutter run

# Run all tests
fvm flutter test

# Build Android APK (release)
fvm flutter build apk --release
```
