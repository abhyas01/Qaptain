# Qaptain

**Qaptain** is a SwiftUI iOS app for managing classroom quizzes. Teachers can create classrooms, build multiple-choice quizzes, and monitor student progress in real-time. Students join classrooms using secure passwords, take interactive quizzes, and track their performance instantly.

## Overview

* **Platform:** iOS (SwiftUI)
* **Language:** Swift
* **Architecture:** ObservableObject state management with singleton controllers/providers
* **Backend:** Firebase Firestore
* **Dependencies:** Firebase (Core, Auth, Firestore)

## App Demos

**App Working**

https://github.com/user-attachments/assets/c4ae4ea2-fde0-4eee-8918-5f1a6f4fe644

**Authentication & Onboarding Demo**

https://github.com/user-attachments/assets/735b580f-94aa-4ee2-abf1-11233c14e60b

## Features

### Authentication

* Email/password sign up and sign in via Firebase Auth
* Forgot password flow with email reset
* Reactive UI bound to authentication state

### Classrooms

* Two roles: **Teacher (creator)** and **Student (member)**
* Teachers can create classrooms (with auto-generated passwords)
* Students join classrooms using a password
* Search classrooms by name, creator, and creation month/year
* Sort classrooms by newest/oldest
* Pull-to-refresh and **pagination** support

### Quizzes

* Create quizzes with a name, deadline, and multiple questions
* Validate unique quiz names per classroom
* View quizzes for a classroom, sorted by creation date or deadline
* Take quizzes; attempts are stored in stats
* Teachers can view aggregated quiz stats for all students

### Members & Management

* View all classroom members
* Teachers can remove members (with automatic cleanup of their quiz stats)
* Regenerate classroom passwords

### Onboarding & Help

* First-launch detection to show an Instructions screen
* Instructions accessible from the Classrooms toolbar

### UX Details

* Splash screen overlay
* Toolbar sorting menu
* Searchable lists
* Accessibility labels and combined elements in info cards

## Project Structure (Selected Files)

| File                       | Description                                                                                              |
| -------------------------- | -------------------------------------------------------------------------------------------------------- |
| [**QaptainApp.swift**](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/QaptainApp.swift) | App entry point; configures Firebase and wires up the auth environment object                            |
| [**ContentView.swift**](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Views/ContentView.swift) | Root view that switches between AuthenticatedView, AuthView, or a loading state based on AuthController  |
| [**AuthController.swift**](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Auth/Controller/AuthController.swift) | ObservableObject singleton managing Firebase Auth, UI states, and auth workflows                         |
| [**DataManager.swift**](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Manager/DataManager.swift) | Firestore data layer singleton for users, classrooms, quizzes, and stats                                 |
| [**ClassroomsView.swift**](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/TabViews/Classrooms/ClassroomsView.swift) | Main navigation for classrooms with segmented control, search, sorting, refresh, and modals              |
| [**InstructionsView.swift**](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/TabViews/Classrooms/InstructionsView.swift) | Onboarding and help view detailing app features for teachers and students                                |

_Additional views/providers/models exist for classroom details, quiz creation, enrollment, and stats_

## Data Model (Firestore)

### Collections and Subcollections

<img width="4668" height="4370" alt="schema-qaptain-firebase" src="https://github.com/user-attachments/assets/005cab77-0bcf-435f-9d91-0d45380a51db" />

### DataManager Responsibilities

[DataManager](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Manager/DataManager.swift) centralizes all Firestore interactions, including:

* Creating/deleting classrooms and quizzes
* Enrolling/removing members
* Updating names and propagating to related documents
* Submitting and retrieving stats
* Querying with ordering and pagination hooks

## App Flow

1. [**QaptainApp.swift**](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/QaptainApp.swift) configures Firebase and listens for auth changes via [**AuthController.swift**](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Auth/Controller/AuthController.swift).
2. [**ContentView.swift**](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Views/ContentView.swift) displays a [SplashScreen.swift](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Views/SplashScreen.swift) overlay, then routes to [**AuthView.swift**](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Auth/View/AuthView.swift) or [**AuthenticatedView.swift**](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Views/AuthenticatedView.swift) based on auth state.
3. [**ClassroomsView.swift**](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/TabViews/Classrooms/ClassroomsView.swift) is the primary entry for authenticated users, with segmented control for Enrolled vs Teaching classes, search, sort, and actions to create/enroll.
4. [**InstructionsView.swift**](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/TabViews/Classrooms/InstructionsView.swift) is shown on first launch and available from the toolbar.

## Setup

### 1. Prerequisites

* **Xcode 15+** (modern SwiftUI APIs)
* CocoaPods or Swift Package Manager not required for Firebase if you already include it via project settings; otherwise add Firebase packages
* **Firebase project** with iOS app configured

### 2. Firebase Configuration

* Add GoogleService-Info.plist to the app target
* Enable Email/Password in Firebase Authentication
* Create Firestore database (in Native mode)

### 3. Install Firebase SDKs

If using Swift Package Manager, add:

* `FirebaseAuth`
* `FirebaseFirestore`
* `FirebaseCore`

Ensure:

```swift
FirebaseApp.configure()
```

is called (already handled in `QaptainApp.init()`).

### 4. Run

1. Open the project in **Xcode**
2. Select an iOS Simulator or device
3. **Build & Run**

## Accessibility

* Uses accessibility labels and combines card content for coherent VoiceOver reading.
* Descriptive labels for toolbar and buttons

## Coding Conventions

* SwiftUI-first architecture with `@State`, `@StateObject`, and `@EnvironmentObject`
* Singletons for cross-cutting controllers ([AuthController.swift](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Auth/Controller/AuthController.swift), [DataManager.swift](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Manager/DataManager.swift))
* Clear logging for major actions and errors
* Input cleaning and validation for user data

## License
Qaptain is under the [MIT License](https://github.com/abhyas01/Qaptain/blob/main/LICENSE.md)
