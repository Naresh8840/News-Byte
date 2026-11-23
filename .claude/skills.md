# News Byte project rules

## Working in the repository

- Before changing a feature, inspect its entry points, callers, tests, dependencies, and API contract. Follow the structure and conventions that the app actually uses.
- Keep each change scoped to the task. Reuse existing code where its behavior fits. Check all callers before changing a shared widget, model, repository, or Cubit contract, and preserve compatibility where the task allows.
- Place code with the feature that owns it and move it into shared code when multiple features need the same behavior. Choose abstractions that solve a concrete problem.

## Dart and Flutter UI

- Use `snake_case` for files and directories, `PascalCase` for types, and `camelCase` for members. Name flags by what they mean, such as `isLoading` or `hasMore`.
- Prefer `final` for values that stay fixed, `const` where possible, and composition for UI. Extract substantial UI sections into focused widgets and keep feature-only widgets private.
- Use the app's existing theme, shared widgets, and asset conventions. Reuse matching design tokens and assets. When implementing a supplied design, verify typography, spacing, and assets before coding.
- Keep network requests and business decisions out of `build()`. Use lazy builders for long lists and provide loading, empty, error, and retry states as appropriate. Give remote images a fallback and keep text scaling and accessible labels in mind.

## Architecture, Cubit, and navigation

- Follow the app's feature-first MVVM structure. Views render state and forward actions, Cubits coordinate feature behavior, and repositories handle data access. Inject dependencies through constructors to keep features testable.
- Represent rendered data and request status in immutable Cubit state. Use value equality that includes values that affect rendering. Use `BlocBuilder` for rendering, `BlocListener` for one-off effects such as navigation or messages, and `context.read` for dispatching actions. Narrow rebuilds with `BlocSelector` or `buildWhen` when useful, while covering all relevant state transitions.
- Scope each Cubit to the flow that owns it and initialize it once per scope. Dispose controllers, cancel timers and subscriptions, and cancel or discard obsolete requests when their scope ends.
- Follow the app's existing navigation approach. Pass typed arguments where practical, handle invalid inputs, and preserve the feed's scroll position and query when returning from article detail.

## API and models

- Use the shared Dio client with consistent timeouts and request configuration. Keep endpoint details and JSON parsing behind the repository. Use query parameters for GET filters and pagination, and request bodies for mutations when required by the API contract.
- Return typed data from repositories and centralize conversion of network and decoding errors into the app's failure type. Cover timeouts, connectivity, cancellation, HTTP errors, and malformed payloads. Treat cancelled or obsolete requests as silent when expected.
- Validate response shapes before decoding. Model fields according to the API contract and handle absent optional values and unknown enum values. Preserve failure semantics for non-success responses and keep raw technical errors out of user-facing messages.
- Keep credentials out of source and logs. Follow the repository's existing serialization approach and regenerate generated code after relevant model changes.

## Feed, search, and pagination

- Keep initial loading, refresh, and load-more states distinct. Preserve visible articles on refresh or pagination failure and let the user retry the failed operation.
- Allow one load-more request for the active feed at a time. Deduplicate by stable article ID, preserve API order, and advance pagination only after a successful response. Stop when the API indicates the end or the continuation fails to advance.
- Debounce search where appropriate. Reset pagination when the active query or filter changes, and cancel or ignore responses from superseded requests.

## Verification and delivery

- Cover changed behavior with focused tests when needed. Prioritize Cubit transitions, JSON decoding, error mapping, and refresh or pagination failures. Test critical UI states or navigation when those change.
- Format changed Dart files and run `flutter analyze` and the relevant `flutter test` suite for code changes. Report checks that failed or could not be run.
- Follow the repository's branch and review conventions. Keep commits focused and document behavior changes, affected callers, and verification in the pull request. Include screenshots when useful for UI review.
