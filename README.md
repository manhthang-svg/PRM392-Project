# Origami

Flutter application for learning, creating, and sharing origami.

## Architecture

```text
lib/
|-- app/
|   |-- app.dart
|   |-- app_shell.dart
|   |-- routes.dart
|   `-- theme.dart
|-- core/
|   |-- constants/
|   |-- network/
|   |-- state/
|   |-- utils/
|   `-- widgets/
|-- features/
|   |-- auth/
|   |-- newsfeed/
|   |-- explore/
|   |-- contribution/
|   |-- chat/
|   `-- profile/
`-- main.dart
```

Each feature owns its screens and business flow. Shared application state,
network clients, constants, utilities, and reusable widgets live under
`core/`.

## Features

- Splash and login flow.
- Multi-image Newsfeed posts.
- User search, public profiles, followers, following, and follow controls.
- Tutorial library with category, difficulty, and duration filters.
- Tutorial detail, step player, comments, completion, and saved tutorials.
- Creator Studio for posts and instruction submissions.
- Draft, processing, approved, and rejected contribution states.
- Conversation list and complete chat rooms.
- Editable profile and completed-origami achievement history.

## Run

```sh
flutter pub get
flutter run
```

## Verify

```sh
flutter analyze
flutter test
flutter build web --release --no-tree-shake-icons
```
