lib/
│
├── app/                      # Global application configuration
│   ├── routes.dart           # Route definitions and navigation stack management
│   ├── theme.dart            # UI styling configs (Pastel Pink, White, typography)
│   └── app.dart              # Main MaterialApp initialization wrapper
│
├── core/                     # Shared resources and utilities used across the entire app
│   ├── constants/            # Global constants (dimensions, layout strings, API endpoints)
│   ├── network/              # HTTP clients (Dio/Http) and WebSocket handlers for Chat
│   ├── utils/                # Helper functions (Date formatting, watermarking engines)
│   └── widgets/              # Reusable UI atoms (Custom Pink Buttons, Fields, Loaders)
│
├── features/                 # CORE DIRECTORY: Segmented by functional business flows
│   │
│   ├── auth/                 # Authentication Flow (Splash screen, Login screen)
│   │
│   ├── newsfeed/             # Social Feed Flow (Origami newsfeed timeline, comments)
│   │
│   ├── explore/              # Core Experience (Library, Browse, Step-by-step viewer)
│   │
│   ├── contribution/         # Creator Studio (Creation workflows, submission state logs)
│   │
│   ├── chat/                 # Messaging Platform (Direct messages, active chatrooms)
│   │
│   └── profile/              # Personal Hub (Profile configs, historical achievements)
│
└── main.dart                 # Application entry point (main function)