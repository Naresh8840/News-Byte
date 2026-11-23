# News Byte — Product Requirements Document

Nov 23, 2026 ·

## Project Overview

**News Byte** is a cross-platform mobile application built with Flutter that delivers spaceflight and aerospace news from multiple publishers in a clean, browsable feed. It consumes the [Spaceflight News API v4](https://api.spaceflightnewsapi.net/v4/) — a free, public REST API that aggregates articles from sources like NASA, SpaceNews, Arstechnica, ESA and others.

**Target users:** Anyone interested in space and aerospace news who wants a lightweight, fast reader without account creation or paywalls.

**Core capabilities:**

1. Browse a paginated feed of spaceflight articles (10 per page, offset-based)
2. Search articles by title with debounced input
3. Filter by news site (server-side) via chip selection
4. Swipe through article details with a full-screen PageView
5. Share articles and open the original source in an external browser
6. Light and dark theme that follows the system setting

| Attribute | Value |
| --- | --- |
| Framework | Flutter 3.x (Dart 3.10+) |
| State management | flutter\_bloc / Cubit |
| Networking | Dio 5.x with interceptors |
| API | Spaceflight News API v4 (REST, JSON) |
| Architecture | Feature-first MVVM |
| Serialization | json\_serializable + json\_annotation |
| Min Android SDK | 21 (Android 5.0) |
| Target platforms | Android (primary), iOS (ready) |

## Requirement Analysis & Planning

### Starting point

The project began from a PDF design reference showing a spaceflight news reader with two screens: a feed list and a detail view. The design specified a royal indigo color scheme (primary #1A237E), card-based article layout, search capability, and a swipeable detail screen.

### Analysis of the design

Before writing any code, the design was broken down into concrete requirements:

1. **API contract** — The Spaceflight News API v4 returns paginated JSON with `count`, `next`, `previous` and `results`. Each article has `id`, `title`, `url`, `image_url`, `news_site`, `summary`, `published_at`, `updated_at`, `featured` and an `authors` array. Pagination uses `offset` + `limit` query parameters, and filtering supports `news_site` (exact match) and `title_contains` (search).
2. **Screen inventory** — Three screens identified: Splash (animated brand intro), News List (feed + search + filter), News Detail (swipeable full article view).
3. **State complexity** — The list screen manages five distinct states (initial, loading, loaded, paginating, error) plus sub-states for search query, selected filter and pagination. The detail screen manages its own article list, pagination bridging from the list screen, favourites and external actions.
4. **Offline and error handling** — The API is remote and unreliable in mobile conditions, so every network path needs timeout handling, connectivity checks, cancellation support and user-facing error messages.

### Key decisions made during planning

| Decision | Rationale |
| --- | --- |
| Cubit over Bloc | Simpler API for this app's complexity; no event classes needed. Methods on the Cubit map directly to user actions. |
| Feature-first folder structure | Each feature owns its view, view\_model and model. Shared code lives in `core/`. Scales without cross-feature coupling. |
| Server-side filtering (not client-side) | Initially filters were applied locally. Switched to server-side `news_site` query param so pagination returns filtered results and the user sees a full page of matching articles. |
| json\_serializable over manual parsing | Generated code reduces boilerplate and serialization bugs. `fieldRename: FieldRename.snake` handles the API's snake\_case convention. |
| Offset pagination over cursor | The API uses offset/limit, so the app tracks the current offset in state and advances it after each successful page. |
| Constructor injection for repositories | Every Cubit accepts an optional `repository` parameter, defaulting to the real implementation. Tests inject a mock with no DI framework needed. |

## Architecture

### Pattern: Feature-first MVVM with Cubit

The app follows MVVM where Views render state and forward user actions, ViewModels (Cubits) coordinate business logic and emit immutable state objects, and Repositories abstract data access behind a clean interface.

### Folder structure

```
lib/
├─ main.dart                          # Entry point
├─ app/
│  ├─ app.dart                        # MaterialApp, BlocProvider, routing
│  └─ theme/app_theme.dart            # Light + dark ThemeData
├─ core/
│  ├─ constants/constants.dart        # Base URL, page size, timeouts
│  ├─ network/
│  │  ├─ dio_helper.dart              # Dio singleton with interceptors
│  │  ├─ api_exception.dart           # Typed exception class
│  │  └─ http_urls.dart               # Endpoint paths
│  ├─ routes/app_routes.dart          # Named routes + PageBuilder
│  ├─ utils/                          # ColorResource, DateFormatter, StringResource
│  └─ widgets/                        # CachedImage, CustomButton, CustomText, EmptyView, ErrorView, ShimmerLoading
└─ features/
   ├─ splash/splash_screen.dart       # Animated splash with fade + scale
   └─ news/
      ├─ model/                       # Article, Author, ArticlesResponse (+.g.dart)
      ├─ repository/news_repository.dart
      ├─ news_list/
      │  ├─ view/screens/              # NewsListScreen
      │  ├─ view/widgets/              # ArticleCard, NewsSiteChips, SearchBarWidget
      │  └─ view_model/                # NewsListCubit + NewsListState
      └─ news_details/
         ├─ view/screens/              # NewsDetailScreen
         ├─ view/widgets/              # DetailAppBar
         └─ view_model/                # NewsDetailCubit + NewsDetailState
```

### Dependency flow

Dependencies flow in one direction: **View → Cubit → Repository → Dio**. Views never call the repository directly. The repository never knows about UI state. Dio is configured once as a singleton (`DioHelper`) with interceptors for error mapping and logging.

### State management approach

- `BlocProvider` at the app root provides `NewsListCubit` (lives for the app's lifetime since the feed persists across navigation)
- `BlocProvider` at route level provides `NewsDetailCubit` (scoped to the detail screen's lifecycle)
- `BlocBuilder` with `buildWhen` narrows rebuilds — the chip bar only rebuilds when `newsSites` or `selectedNewsSite` changes
- `BlocListener` bridges the list cubit's pagination updates into the detail cubit when viewing articles

## Data Layer

### Models

Three model classes map the API's JSON contract:

| Model | Fields | Notes |
| --- | --- | --- |
| `Article` | id, title, url, imageUrl, newsSite, summary, publishedAt, updatedAt, featured, authors | `@JsonSerializable(fieldRename: FieldRename.snake)` handles API naming. `authorName` getter falls back to `newsSite` when authors is empty. Equatable by `id` only. |
| `Author` | name | Nested inside Article's authors array. |
| `ArticlesResponse` | count, next, previous, results | Wraps paginated API response. `hasMore` getter checks `next != null`. |

All models are immutable with `const` constructors. Generated `.g.dart` files handle serialization.

### Repository

`NewsRepository` exposes three methods:

1. `getArticles({offset, limit, newsSite, cancelToken})` — Fetches paginated articles with optional server-side filter
2. `searchArticles({query, offset, limit, newsSite, cancelToken})` — Searches by `title_contains` with optional filter
3. `getArticleById(id)` — Fetches a single article by ID

The repository returns typed `ArticlesResponse` or `Article` objects. All network errors propagate as `DioException` to the Cubit layer for handling.

### Dio client (DioHelper)

A singleton configured once at app startup:

- **Base URL:** `https://api.spaceflightnewsapi.net/v4`
- **Timeouts:** 15s connect, 15s receive
- **Headers:** `Accept: application/json`
- **Global CancelToken** attached via request interceptor

### Error handling pipeline

The Dio error interceptor converts every failure into a typed `ApiException` with a user-friendly message:

| Error type | Mapped message |
| --- | --- |
| HTTP 400 | Bad request |
| HTTP 403 | Access denied |
| HTTP 404 | Resource not found |
| HTTP 429 | Too many requests. Please wait a moment |
| HTTP 500/502/503 | Server error. Please try later |
| Connection timeout | Connection timed out. Please try again |
| Socket / connection error | No internet connection. Please check your network |
| Cancel | Request was cancelled (silent in Cubits) |

Cubits extract the message from `DioException.error` as `ApiException` and emit it into the error state. Raw technical errors never reach the UI.

## Feature: News Feed (List Screen)

### Screen layout

The list screen is composed of four vertical sections:

1. **Header** — "Discover" title with subtitle "News from all around the world"
2. **Search bar** — Debounced text input (1000ms) that searches by `title_contains`
3. **Filter chips** — Horizontal scrollable `ChoiceChip` list extracted from loaded articles, with an "All" option
4. **Article list** — `ListView.builder` (single column) or `SliverGrid` (tablet: 2–3 columns based on screen width)

### NewsListCubit — state machine

The cubit manages the full lifecycle of the feed:

| Method | Trigger | What it does |
| --- | --- | --- |
| `loadArticles()` | Screen init | Emits Loading → calls `getArticles()` → emits Loaded with articles + extracted newsSites |
| `loadMore()` | Scroll near bottom | Guards against duplicate calls. Passes current offset + selected newsSite. Deduplicates by article ID. Merges new sites into chip list when unfiltered. |
| `search(query)` | Debounced input | Cancels previous request via CancelToken. Resets pagination. Preserves active filter. |
| `filterByNewsSite(site)` | Chip tap | Cancels previous filter request. Emits `isFilterLoading: true` (chips stay visible, list shows shimmer). Makes fresh API call with `news_site` param. Resets offset to 0. |
| `refresh()` | Pull-to-refresh | Re-fetches page 1 with current search + filter. Replaces all articles. |

### NewsListState

Immutable state class using Equatable:

| Field | Type | Purpose |
| --- | --- | --- |
| `articles` | `List<Article>` | Currently loaded articles |
| `hasReachedMax` | `bool` | True when API returns no `next` URL |
| `searchQuery` | `String` | Active search text |
| `selectedNewsSite` | `String?` | Active filter (null = all) |
| `newsSites` | `List<String>` | Stored site names for chips (survives filter changes) |
| `isPaginating` | `bool` | Shows bottom loader |
| `isFilterLoading` | `bool` | Shows shimmer while filter API call runs |
| `paginationError` | `bool` | Shows retry option on load-more failure |
| `offset` | `int` | Current pagination offset |

### Server-side filtering (improvement over initial approach)

**Before:** `filterByNewsSite()` was synchronous — it set `selectedNewsSite` on the state and a `filteredArticles` getter filtered the already-loaded articles client-side. Problem: if 10 mixed articles were loaded and only 2 matched "Arstechnica", the user saw 2 items with a pagination spinner, loading more mixed pages to trickle in matches one by one.

**After:** `filterByNewsSite()` is now async — it makes a fresh API call with `news_site=Arstechnica` as a query parameter. The API returns 10 Arstechnica articles immediately. Pagination continues with the same filter: `offset=10&news_site=Arstechnica`. The chip list is stored separately in state so it persists across filter changes.

### Pagination mechanics

- `offset` tracks how many articles have been loaded
- Each `loadMore()` call passes the current offset to the API
- Response articles are deduplicated by `id` against existing articles
- `hasReachedMax` is set when the API's `next` field is null
- Guards prevent concurrent pagination requests
- `loadMore` is blocked during `isFilterLoading`

## Feature: Article Detail

### Screen design

The detail screen uses a `PageView.builder` so users swipe horizontally between articles. Each page is a `CustomScrollView` with:

- **SliverAppBar** (300px expanded height) — Hero image with gradient overlay, news site badge, title, relative timestamp ("2h ago"), back button, bookmark toggle and share menu
- **Detail body** — Author avatar (first letter circle), author name, formatted date, full article summary
- **Bottom bar** — Fixed "Read Full Article" button that launches the original URL in an external browser

### NewsDetailCubit

| Method | Behavior |
| --- | --- |
| `init(articles)` | Receives the article list from the list screen. Emits `NewsDetailLoaded`. |
| `onPageChanged(index)` | Triggers `loadMore` when the user is within 3 articles of the end (pre-fetch threshold). |
| `updateArticles(articles, isPaginating, paginationError)` | Called via `BlocListener` on the list cubit. Only updates if the new list is longer (new page loaded). |
| `toggleFavourite(articleId)` | Toggles article ID in an in-memory `Set<int>`. Bookmark icon updates immediately. |
| `openArticleUrl(url)` | Parses and launches URL via `url_launcher` in external application mode. |
| `shareArticle(title, url)` | Shares title + URL via `share_plus` native share sheet. |

### How the detail bridges to the list cubit

The detail screen is created with a callback to the list cubit's `loadMore()`:

```
NewsDetailCubit(
  onLoadMore: () => newsListCubit.loadMore(),
)..init(args.articles);
```

A `BlocListener<NewsListCubit, NewsListState>` on the detail screen listens for state changes. When the list cubit loads more articles, the detail cubit receives the updated list and extends its `PageView`. This creates seamless infinite scrolling across both screens.

### Pagination page

When the user swipes past the last loaded article while more are loading, they see a pagination indicator page. If pagination fails, a retry button appears. The `pageCount` getter adds 1 to the article count when paginating or showing an error, so the PageView has an extra page for this UI.

### NewsDetailState

| Field | Type | Purpose |
| --- | --- | --- |
| `articles` | `List<Article>` | Full article list (grows as pages load) |
| `favouriteIds` | `Set<int>` | In-memory bookmarked article IDs |
| `isPaginating` | `bool` | Shows loading indicator on the extra page |
| `paginationError` | `bool` | Shows retry button on the extra page |

## UI/UX Implementation

### Dual theme system

The app supports light and dark themes that follow the system setting via `ThemeMode.system`. Both themes are defined in `AppTheme` using Material 3 (`useMaterial3: true`) with `ColorScheme.fromSeed` based on royal indigo (#1A237E).

| Token | Light | Dark |
| --- | --- | --- |
| Primary | #1A237E | #3949AB |
| Scaffold background | #F8F9FA | #121212 |
| Card | White | #1E1E1E |
| Chip (unselected) | #E8E8E8 | #2C2C2C |
| Chip (selected) | #1A237E | #3949AB |
| Input fill | #EEEEEE | #2C2C2C |

Typography uses Google Fonts (Nunito Sans) applied via `GoogleFonts.nunitoSansTextTheme`. System UI overlays (status bar, navigation bar) are explicitly styled per screen for a polished look.

### Shared widgets

| Widget | Purpose |
| --- | --- |
| `CachedImage` | Wraps `CachedNetworkImage` with shimmer placeholder and error fallback icon. Handles empty URLs. |
| `CustomText` | Thin wrapper around `Text` with consistent `maxLines` and `overflow` handling. |
| `CustomButton` | `ElevatedButton` with optional icon and `isExpanded` mode for full-width layout. |
| `ShimmerListLoader` | 6-item skeleton loader matching the article card layout. Theme-aware base/highlight colors. |
| `ShimmerDetailLoader` | Full-page skeleton matching the detail screen (image area + text blocks). |
| `EmptyView` | Centered message for empty states (no results, no articles). |
| `ErrorView` | Error message with retry button. |

### Loading states

Every async operation has a corresponding loading state:

- **Initial load** → `ShimmerListLoader` (6 skeleton cards)
- **Pagination** → `CircularProgressIndicator` at bottom of list
- **Filter change** → `ShimmerListLoader` (chips stay visible via `isFilterLoading` flag)
- **Search** → Full shimmer reload
- **Image loading** → Per-image shimmer via `CachedNetworkImage` placeholder
- **Detail pagination** → Dedicated pagination page in PageView

### Responsive layout

The article list adapts to screen width:

- Under 600px → single-column `ListView`
- 600–899px → 2-column `SliverGrid`
- 900px+ → 3-column `SliverGrid`

Grid items use a fixed `mainAxisExtent` of 120px for consistent card heights.

### Splash screen

Animated brand intro using `AnimationController` with two concurrent animations:

- Fade in (0% → 60% of duration)
- Scale from 0.8 to 1.0 with `Curves.easeOutBack` (bounce effect)

Auto-navigates to the feed after 2200ms with a `FadeTransition` route.

## Testing Strategy

### Tools

- **bloc\_test** — Declarative Cubit state transition testing
- **mocktail** — Mock generation without codegen (simpler than mockito for Dart)
- **flutter\_test** — Standard test runner

### Mock setup

`MockNewsRepository extends Mock implements NewsRepository` provides a test double. Helper functions `_stubGetArticles` and `_stubSearchArticles` stub all named parameters (including the new `newsSite` and `cancelToken`) with `any(named: ...)` matchers.

A `_testArticle()` factory creates articles with configurable `id` and `newsSite` for each test scenario.

### NewsListCubit tests (13 tests)

| Group | Test | What it verifies |
| --- | --- | --- |
| loadArticles | emits \[loading, loaded\] on success | Full happy path: state transitions, article count, offset, newsSites extraction |
| loadArticles | emits \[loading, error\] on DioException | ApiException message propagates to error state |
| loadArticles | does not emit if already loading | Guard against duplicate loads |
| loadMore | appends new articles and deduplicates | Offset advances, articles merge, no duplicate IDs |
| loadMore | does nothing if already paginating | Concurrent pagination guard |
| loadMore | does nothing if reached max | End-of-feed guard |
| refresh | emits loaded with fresh data | Full list replacement with new articles |
| search | emits \[loading, loaded\] with search results | Query forwarded, results returned |
| search | skips duplicate search query | Same query string does not trigger a second API call |
| filterByNewsSite | makes API call with news\_site filter | Emits isFilterLoading:true, then loaded with server-filtered results, newsSites preserved |
| filterByNewsSite | clears filter with fresh API call | null filter triggers unfiltered API call, chips updated |
| filterByNewsSite | does nothing if same site selected | No-op guard |
| filterByNewsSite | does nothing if state is not loaded | Guard against filter on non-loaded state |

### What the tests cover

- Every Cubit method's happy path and primary failure mode
- State transition sequences (loading → loaded, loading → error)
- Pagination guards (already paginating, reached max, filter loading)
- Deduplication logic
- Server-side filter lifecycle (isFilterLoading flag, newsSites preservation)
- Search debounce skip on duplicate query
- CancelToken and newsSite parameter forwarding to the repository

## Build & Delivery

### Commit history

The project was built incrementally in focused commits:

| Commit | Scope |
| --- | --- |
| `initial commit` | Flutter project scaffolding |
| `App icon generation` | Custom launcher icon via flutter\_launcher\_icons |
| `Base setup app, constants, theme` | MaterialApp, AppTheme (light + dark), constants, color/string resources |
| `setup and network handling using dio` | DioHelper singleton, interceptors, ApiException, HTTP URLs |
| `Reusable widgets implementation` | CachedImage, CustomButton, CustomText, EmptyView, ErrorView, ShimmerLoading |
| `Model and data implementation` | Article, Author, ArticlesResponse models + json\_serializable, NewsRepository |
| `news list screen implementation` | NewsListCubit, NewsListState, NewsListScreen, ArticleCard, SearchBar, NewsSiteChips |
| `news detail screen implementation` | NewsDetailCubit, NewsDetailState, NewsDetailScreen, DetailAppBar, PageView, share, URL launch |
| `minor improvements` | Server-side filtering, isFilterLoading, test updates, Android internet permission |

### Build configuration

- **Android:** Internet permission added to `AndroidManifest.xml`
- **APK:** Release build via `flutter build apk --release` (\~48 MB)
- **SDK constraint:** Dart ^3.10.0
- **Dependencies:** 13 runtime packages, 6 dev packages

### What ships

- Release APK at `build/app/outputs/flutter-apk/app-release.apk`
- Full source code with clean commit history
- 13 passing unit tests
- Light and dark theme support
- Responsive layout (phone + tablet)

## Summary

News Byte demonstrates a production-grade approach to building a Flutter news reader — clean architecture, testable state management, robust error handling and a polished dual-theme UI.

### Key decisions at a glance

| Area | Decision | Why it matters |
| --- | --- | --- |
| Architecture | Feature-first MVVM with Cubit | Each feature is self-contained. Views, state and data access have clear boundaries. No cross-feature coupling. |
| State management | flutter\_bloc (Cubit) | Predictable unidirectional flow. Immutable state with Equatable. `buildWhen` narrows rebuilds. |
| Networking | Dio singleton with interceptor pipeline | One place for timeouts, error mapping, logging and cancellation. User-friendly messages on every failure path. |
| Filtering | Server-side via API query param | Full page of filtered results on first load. Pagination respects the filter. No client-side trickle. |
| Pagination | Offset-based with deduplication | Tracks position in state. Guards against concurrent loads. Deduplicates by article ID. Bridges into the detail screen. |
| Testing | Cubit-focused with mocktail | 13 tests covering every method, guard and state transition. Mock repository injected via constructor. |
| Theming | Dual theme following system | Material 3 with custom color tokens. Every component styled for both modes. Google Fonts for consistent typography. |
| Code generation | json\_serializable | Type-safe serialization matching the API's snake\_case contract. No manual parsing errors. |

### For the reviewer

The codebase is intentionally straightforward — no over-engineering, no unnecessary abstractions. Each pattern solves a concrete problem: Cubits separate UI from logic, the repository abstracts the API, interceptors centralize error handling, and immutable state prevents stale-data bugs. The server-side filtering improvement shows the kind of iteration that happens during real development: an initial approach was identified as suboptimal (client-side filtering with pagination), analyzed, and replaced with the correct server-side approach including updated tests.
