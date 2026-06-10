# Flutter Architecture

## Tech Stack

| Layer             | Technology              |
|-------------------|-------------------------|
| Framework         | Flutter (Stable)        |
| State Management  | Riverpod                |
| Navigation        | GoRouter                |
| Networking        | Dio                     |
| Local Storage     | Flutter Secure Storage  |

---

## Folder Structure

```
lib/
├── app/                    # App entry point, routing, theme setup
├── core/                   # Constants, utilities, base classes, network client
├── shared/                 # Reusable widgets, models, and helpers shared across features
└── features/
    ├── auth/               # Login, Register, Forgot Password, OTP, Verify Email
    ├── newsfeed/           # Newsfeed, Post Detail, Like/Comment/Share/Save
    ├── library/            # Library, Tutorial Detail, Step-by-Step, Achievement
    ├── creator/            # Creator Studio, Create Post, Create Tutorial, Submission Detail
    ├── profile/            # Profile, Saved Items, Settings
    └── messages/           # Conversations, Chat
```

---

## Feature Module Structure

Each feature follows a layered structure:

```
features/<feature_name>/
├── data/
│   ├── datasources/        # Remote and local data sources
│   ├── models/             # Data models (JSON serialization)
│   └── repositories/       # Repository implementations
├── domain/
│   ├── entities/           # Pure business entities
│   ├── repositories/       # Repository interfaces (abstract)
│   └── usecases/           # Business logic use cases
└── presentation/
    ├── pages/              # Full screen pages
    ├── widgets/            # Feature-specific widgets
    └── providers/          # Riverpod providers (state management)
```

---

## Navigation (GoRouter)

- Named routes for all screens
- Redirect guards for authentication state
- Nested navigation for bottom navigation bar tabs

---

## State Management (Riverpod)

- `StateNotifierProvider` for mutable state (e.g. form state, lists)
- `FutureProvider` for async data fetching
- `StreamProvider` for real-time updates

---

## Networking (Dio)

- Base URL configured via environment variables
- Interceptors for:
  - Auth token injection
  - Error handling & logging
  - Token refresh (if applicable)

---

## Local Storage (Flutter Secure Storage)

- Store auth tokens securely
- Store user preferences
