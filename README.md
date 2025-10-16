# Qaptain

<div align="center">
    <img
      width="150"
      alt="Qaptain"
      src="https://github.com/user-attachments/assets/fb336656-9399-4b70-a484-5cc964c8f689" 
    />
    <p>Create. Quiz. Track.</p>
</div>

  - **Qaptain** is a SwiftUI iOS app for managing classroom quizzes.
  - Teachers can create classrooms, build multiple-choice quizzes, and monitor student progress in real-time.
  - Students join classrooms using secure passwords, take interactive quizzes, and track their performance instantly.

## Overview
  
  * **Platform:** iOS (SwiftUI)
  * **Language:** Swift
  * **Architecture:** ObservableObject state management with singleton controllers/providers
  * **Backend:** Firebase Firestore
  * **Dependencies:** Firebase (Core, Auth, Firestore)

## App Demos

  - ### App Working (3 minutes)

    https://github.com/user-attachments/assets/c1ce079c-a518-49dd-a248-0ac0dd3d169a

  - ### Authentication & Onboarding (< 1 minute)

    _**Splash screen** appears on launch, followed by **login** and **onboarding**_
    
    https://github.com/user-attachments/assets/6ffa71cf-49b7-4739-b950-3ef5e7d36e60

## Features

  - ### Authentication
    * Email/password sign up and sign in via Firebase Auth
    * Forgot password flow with email reset
    * Reactive UI bound to authentication state
  
  - ### Classrooms
    * Two roles: **Teacher (creator)** and **Student (member)**
    * Teachers can create classrooms (with auto-generated passwords)
    * Validate classroom name uniqueness per teacher (a teacher cannot create two classrooms with the same name)
    * Students join classrooms using a password
    * Search classrooms by name, creator, and creation month/year
    * Sort classrooms by newest/oldest
    * Pull-to-refresh and **pagination** support
  
  - ### Quizzes
    * Create quizzes with a name, deadline, and multiple questions
    * Validate quiz name uniqueness per classroom (each classroom cannot have duplicate quiz names)
    * View quizzes for a classroom, sorted by creation date or deadline
    * Take quizzes; attempts are stored in stats
    * Teachers can view aggregated quiz stats for all students
  
  - ### Members & Management
    * View all classroom members
    * Teachers can remove members (with automatic cleanup of their quiz stats)
    * Regenerate classroom passwords
  
  - ### Onboarding & Help
    * First-launch detection to show an Instructions screen
    * Instructions accessible from the Classrooms toolbar

## User Experience & Design

  - ### UX Details
    * Splash screen overlay
    * **Loading**, **Retry**, and **Error** states are clearly displayed for all CRUD and data-fetching operations
    * Validates input as you type and updates _submit_ buttons accordingly
    * Searchable and refreshable (pull-to-refresh) lists with a sorting menu on the toolbar

  - ### Accessibility
    * Uses accessibility labels and combines card content for coherent **VoiceOver** reading
    * Descriptive labels for toolbar and buttons

  - ### Adaptive & Responsive Design
    * Automatically switches between **light** and **dark** mode for a consistent look
    * Responsive on all **iPhone** and **iPad** screens, in both **portrait** and **landscape**

## Project Structure (Selected Files)

  | File                       | Description                                                                                              |
  | -------------------------- | -------------------------------------------------------------------------------------------------------- |
  | [`QaptainApp.swift`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/QaptainApp.swift) | App entry point; configures Firebase and wires up the auth environment object                            |
  | [`ContentView.swift`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Views/ContentView.swift) | Root view that switches between [`AuthenticatedView`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Views/AuthenticatedView.swift), [`AuthView`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Auth/View/AuthView.swift), or a loading state based on [`AuthController`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Auth/Controller/AuthController.swift)  |
  | [`AuthController.swift`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Auth/Controller/AuthController.swift) | ObservableObject singleton managing Firebase Auth, UI states, and auth workflows                         |
  | [`DataManager.swift`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Manager/DataManager.swift) | Firestore data layer singleton for users, classrooms, quizzes, and stats                                 |
  | [`ClassroomProvider.swift`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Providers/ClassroomProvider.swift) | Singleton ObservableObject that fetches, caches, and manages classroom data with **pagination**, filtering, and UI state updates                            |
  | [`ClassroomsView.swift`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/TabViews/Classrooms/ClassroomsView.swift) | Main navigation for classrooms with segmented control, search, sorting, refresh, and modals              |
  | [`NetworkMonitor.swift`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Network/NetworkMonitor.swift) | Singleton ObservableObject that monitors real-time network connectivity and updates UI via published properties                                |
  | [`NetworkAlertModifier.swift`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Network/NetworkAlertModifier.swift) / [`View+Extension.swift`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Extensions/View%2BExtension.swift) | Custom ViewModifier and extension providing automatic network connectivity alerts across the app                                           |
  | [`InstructionsView.swift`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/TabViews/Classrooms/InstructionsView.swift) | Onboarding and help view detailing app features for teachers and students                                |
  
  _Additional views/providers/models exist for classroom details, quiz creation, enrollment, and stats_

## Data Model (Firestore)

  - ### Collections and Subcollections

    <img width="4668" height="4370" alt="schema-qaptain-firebase" src="https://github.com/user-attachments/assets/005cab77-0bcf-435f-9d91-0d45380a51db" />

  - ### DataManager Responsibilities ([`DataManager.swift`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Manager/DataManager.swift))

    - The [`DataManager.swift`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Manager/DataManager.swift) is a central **Singleton class** that strictly handles all direct communication with Firebase Firestore.
    - This architectural choice separates data persistence logic from the UI/view model layer ([`ClassroomProvider.swift`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Providers/ClassroomProvider.swift)) and ensures consistent data validation and cleaning across the application.
    - It primarily relies on Swift's modern **`async/await`** concurrency and uses **completion handlers** for asynchronous results.

      #### Core Functionalities by Data Entity
      
      | Area | Functionality & Key Implementation Details | 
      | ----- | ----- | 
      | **Architectural Core** | **Singleton Pattern:** Enforced with a [`private init()`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Manager/DataManager.swift#L22) and [`static let shared`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Manager/DataManager.swift#L19). | 
      | [**App Launch Management**](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Manager/DataManager.swift#L36) | **Onboarding State:** Manages the app's first-launch state by checking and setting flags in `UserDefaults` ([`hasLaunchedBefore`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Manager/DataManager.swift#L28)) to control the display of onboarding instructions. |
      | **User Management** | **Propagating Name Updates:** The critical [`updateUserNameEverywhere`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Manager/DataManager.swift#L84) function ensures that when a user changes their name, it is consistently updated across: their main [`users`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Model/User.swift) document, every [`members`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Model/Member.swift) subcollection document, the [`createdByName`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Model/Classroom.swift#L18) field in their classrooms, and their [`name`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Model/QuizStat.swift#L18) in all relevant [`stats`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Model/QuizStat.swift) documents. | 
      | [**Classroom Creation**](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Manager/DataManager.swift#L358) | **Uniqueness & Setup:** Validates the classroom name for **uniqueness per creator**. Creates the main Classroom document, automatically generates a unique **password** (`UUID`), and adds the creator as the initial [`member`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Model/Member.swift) ([`isCreator: true`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Model/Member.swift#L18)). | 
      | [**Classroom Enrollment**](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Manager/DataManager.swift#L171) | **Secure Joining:** Searches for classrooms using the join password, verifies the user isn't already enrolled, fetches user profile data, and adds the student to the [`members`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Model/Member.swift) subcollection. | 
      | **Quiz Management & Stats** | **Atomic Creation:** [Creates new quizzes](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Manager/DataManager.swift#L722) after validating **name uniqueness per classroom**. Uses a [`Firestore Batch`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Manager/DataManager.swift#L788) to write all quiz questions simultaneously, ensuring atomicity. <br> <br> **Attempt Tracking:** The [`submitStatsForQuiz`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Manager/DataManager.swift#L1120) method manages student progress, either creating a new [`QuizStat`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Model/QuizStat.swift) record or appending a new [`Attempt`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Model/Attempt.swift) object to an existing list, and updates the [`lastAttemptDate`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Model/QuizStat.swift#L19). | 
      | **Cleanup & Deletion** | **Deep Deletion:** The destructive functions ([`deleteClassroom`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Manager/DataManager.swift#L463), [`deleteQuiz`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Manager/DataManager.swift#L1026), [`removeMember`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Manager/DataManager.swift#L272)) automatically perform **cascading cleanup**. For example, removing a [`member`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Model/Member.swift) triggers the deletion of all their [`QuizStat`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Model/QuizStat.swift) records. Deleting a [`classroom`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Model/Classroom.swift) recursively deletes all its [`quizzes`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Model/Quiz.swift), [`quizQuestions`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Model/Question.swift), [`QuizStats`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Model/QuizStat.swift), and [`members`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Model/Member.swift). | 
      | **Input Validation** | **Data Cleaning:** Uses [`cleanName(withName:)`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Manager/DataManager.swift#L1267) to normalize user input (names, titles) by trimming whitespace, ensuring data integrity before persistence. |

## App Flow

1. [`QaptainApp.swift`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/QaptainApp.swift) configures Firebase and listens for auth changes via [`AuthController.swift`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Auth/Controller/AuthController.swift).
2. [`ContentView.swift`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Views/ContentView.swift) displays a [`SplashScreen.swift`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Views/SplashScreen.swift) overlay, then routes to [`AuthView.swift`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Auth/View/AuthView.swift) or [`AuthenticatedView.swift`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Views/AuthenticatedView.swift) based on [`AuthState`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Auth/Controller/AuthController.swift#L15).
3. The app monitors network connectivity via [`NetworkMonitor.swift`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Network/NetworkMonitor.swift) and displays alerts using the [`.networkAlert()`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Extensions/View%2BExtension.swift#L12) modifier when internet connection is lost, ensuring users are informed before Firebase operations.
4. Classrooms are loaded and observed via [`ClassroomProvider.swift`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Providers/ClassroomProvider.swift) to provide real-time updates, **pagination**, and role-based filtering.
5. [`ClassroomsView.swift`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/TabViews/Classrooms/ClassroomsView.swift) is the primary entry for authenticated users, with segmented control for Enrolled vs Teaching classes, search, sort, and actions to create/enroll.
6. [`InstructionsView.swift`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/TabViews/Classrooms/InstructionsView.swift) is shown on first launch and available from the toolbar.

## Setup

### 1. Prerequisites

* **Xcode 15 or later** (modern SwiftUI APIs)  
* No CocoaPods or Swift Package Manager setup required (Firebase SDKs are already integrated)  
* Internet connection for Firebase Auth & Firestore  

### 2. Firebase Configuration

- The repository already includes a fully configured **`GoogleService-Info.plist`**, so when you **clone the repo**, the app is **immediately linked to Firebase**  

- You can simply **Build & Run** in Xcode to use the existing Firebase Auth and Firestore setup. (no extra configuration needed)

- If you’d like to connect your **own Firebase project** instead:

  - Create a new project in the [Firebase Console](https://console.firebase.google.com/)  
  - Add an iOS app and download your own **`GoogleService-Info.plist`** file  
  - Replace the existing file in the Xcode project  
  - Enable **Email/Password Authentication** and **Cloud Firestore (Native mode)**  

  _Note: The included Firebase configuration is provided for demo and testing purposes only. Do NOT use it for production_

### 3. Run the App

1. Open the project in **Xcode**  
2. Choose an **iOS Simulator** or connected device  
3. Click **Run (⌘ + R)** - the app will launch and automatically connect to Firebase

## Coding Conventions

* SwiftUI-first architecture with `@State`, `@StateObject`, and `@EnvironmentObject`
* Singletons for cross-cutting controllers ([`AuthController.swift`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Auth/Controller/AuthController.swift), [`DataManager.swift`](https://github.com/abhyas01/Qaptain/blob/main/Qaptain/Qaptain/Manager/DataManager.swift))
* Clear logging for major actions and errors
* Input cleaning and validation for user data

## Project Context

Qaptain was developed as the final project for the course [MPCS 51032 Advanced iOS Application Development (Spring 2025)](https://mpcs-courses.cs.uchicago.edu/2024-25/spring/courses/mpcs-51032-1) at the **University of Chicago**.

## Author  

**Developed by:** [Abhyas Mall](https://www.linkedin.com/in/abhyasmall/)  
**Project:** [Qaptain](https://github.com/abhyas01/Qaptain/)  
**Contact:** mallabhyas@gmail.com

## License
Qaptain is under the [MIT License](https://github.com/abhyas01/Qaptain/blob/main/LICENSE.md)
