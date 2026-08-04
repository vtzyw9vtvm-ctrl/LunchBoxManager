# School Lunch Manager Project Specification

## Purpose

School Lunch Manager is a native macOS SwiftUI application for managing school lunch ordering workflows. The app will help organize students, classes, menu items, lunch orders, and import sessions in a way that is simple for school staff to review and maintain.

## Overall Folder Structure

The project uses the existing Xcode application structure:

```text
School Lunch Manager/
├── Documentation/
│   └── PROJECT_SPEC.md
├── School Lunch Manager/
│   ├── Assets.xcassets
│   ├── ContentView.swift
│   ├── Item.swift
│   ├── Models/
│   │   ├── ImportSession.swift
│   │   ├── LunchOrder.swift
│   │   ├── MenuItem.swift
│   │   ├── SchoolClass.swift
│   │   └── Student.swift
│   └── School_Lunch_ManagerApp.swift
├── School Lunch ManagerTests/
└── School Lunch ManagerUITests/
```

Future source folders should stay inside the existing app target group. Do not create a separate Swift Package, `Sources` folder, or second Xcode project unless the project requirements explicitly change.

## MVVM Architecture

The application follows MVVM:

- Models define plain data structures for the school lunch domain.
- Views define SwiftUI interface layout and user interaction.
- View models own presentation state, validation state, and coordination between views and services.

Business rules should not be placed directly in SwiftUI views. Views should remain focused on rendering UI and forwarding user intent to view models.

## Coding Conventions

- Use SwiftUI for app UI.
- Prefer modern Swift concurrency with `async` and `await` when asynchronous work is needed.
- Avoid introducing Combine unless there is a clear project need.
- Prefer `let` for constants and `var` only for values that need mutation.
- Keep model types data-focused and free of business logic unless the behavior is intrinsic to the model.
- Add comments only for non-obvious decisions or complex logic.
- Keep changes scoped to the feature being implemented.

## Naming Conventions

- Types use PascalCase, such as `LunchOrder` and `SchoolClass`.
- Properties, methods, and local variables use camelCase, such as `studentID` and `orderDate`.
- SwiftUI views should end with `View`.
- View models should end with `ViewModel`.
- Service types should use descriptive names that reflect their responsibility.
- File names should match the primary type they contain.

## Swift Version

Use the Swift version configured by the Xcode project. New code should be written in modern Swift style and should remain compatible with the active project toolchain.

## Target macOS Version

Use the macOS deployment target configured by the existing Xcode project. New features should be checked against that deployment target before adopting newer platform APIs.

## Principles for Future Development

- Preserve the existing Xcode project structure.
- Build features incrementally with focused, testable changes.
- Keep domain models simple until real behavior is required.
- Put user-facing state and formatting decisions in view models where practical.
- Keep SwiftUI views readable by extracting focused subviews when screens grow.
- Validate imports and order data before it affects saved application state.
- Prefer clear data flow over hidden side effects.
- Add unit tests for business rules and view model behavior as those layers are introduced.
- Add UI tests for critical ordering and import workflows once those workflows exist.
