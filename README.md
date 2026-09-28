# 💰 Expense Tracker Mobile App

A clean, modern, and high-performance **Expense Tracker Application** built with **Flutter** and **Firebase Cloud Firestore**. Developed as part of the Mobile App Developer Intern selection process for **CyphLab (Pvt) Ltd**.

---

## 🌟 Key Features

### 🎯 Core Features
- [x] **Add New Expenses**: Log expenses with title, amount, category, date, and optional notes.
- [x] **Edit Existing Expenses**: Update any existing expense seamlessly.
- [x] **Delete Expenses**: Delete expenses with safety confirmation dialogs to prevent accidental loss.
- [x] **Expense Categories**: 10 distinct categories with vibrant custom icons and colors (Food, Transport, Bills, Shopping, Groceries, Entertainment, Health, Education, Travel, Other).
- [x] **Cloud Firestore Storage**: Real-time cloud sync with user-scoped data (`users/{userId}/expenses`).
- [x] **Monthly Expense Summary Card**: Interactive card displaying current month spend, transaction count, top spending category, and quick month-to-month switcher.
- [x] **Expense History & Grouping**: Chronological expense list with formatted amounts, category badges, and relative timestamps ("Today", "Yesterday").
- [x] **Multi-Criteria Filtering**: Filter by category chips, custom date ranges, and months.
- [x] **Form Validation**: Strict validation on inputs (valid positive amounts, required fields).
- [x] **Comprehensive UI States**: Dedicated loading indicators, modern empty state illustrations, and actionable error banners.

### 🚀 Additional & Standout Features
- [x] **Interactive Donut & Pie Charts**: Category breakdown visualization built with `fl_chart`.
- [x] **Category Progress Bars**: Percentage-of-budget indicators for each category.
- [x] **Dark & Light Mode**: Complete Material 3 theming with persistent theme preferences using `shared_preferences`.
- [x] **Live Search**: Real-time search bar to quickly filter expenses by title or note description.
- [x] **Firebase Authentication**:
  - Email & Password Sign In and Registration.
  - **One-Tap Guest Mode (Anonymous)**: Instant access for reviewers to test all features without account registration friction!
- [x] **Offline / Resilient Fallback**: Graceful handling when offline or before Firebase credentials are configured.

---

## 🏗️ Architecture & Project Structure

The project adopts a **Layered Clean Architecture** with the **Provider** state management pattern for clear separation of concerns, scalability, and testability.

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart          # Light and dark color palettes
│   │   └── app_categories.dart      # Category definitions with icons and colors
│   ├── theme/
│   │   └── app_theme.dart           # Material 3 ThemeData (Light & Dark)
│   └── utils/
│       ├── currency_formatter.dart  # Formats currency amounts
│       └── date_formatter.dart      # Human-readable and relative date formatting
├── models/
│   ├── category_model.dart          # Data model for expense category
│   └── expense_model.dart           # Expense model with Firestore serialization
├── services/
│   ├── auth_service.dart            # Firebase Authentication wrapper & guest auth
│   └── firestore_service.dart       # Firestore CRUD with real-time stream & fallback
├── providers/
│   ├── auth_provider.dart           # Auth state management
│   ├── expense_provider.dart        # Expense state, filters, and calculations
│   └── theme_provider.dart          # Theme switcher with local storage persistence
├── widgets/
│   ├── custom_text_field.dart       # Reusable styled text field with validation
│   ├── empty_state_widget.dart      # Illustrated empty state placeholder
│   ├── loading_indicator.dart       # Centered loading state widget
│   └── confirm_dialog.dart          # Reusable confirmation modal dialog
├── views/
│   ├── auth/
│   │   └── login_screen.dart        # Login, registration, and guest mode screen
│   ├── home/
│   │   ├── home_screen.dart         # Main view with BottomNavigationBar
│   │   └── widgets/
│   │       ├── monthly_summary_card.dart  # Monthly total and month switcher
│   │       ├── category_chip_bar.dart     # Horizontal category filter chips
│   │       └── expense_list_item.dart     # Expense tile with swipe-to-delete
│   ├── expense/
│   │   ├── add_edit_expense_screen.dart   # Add / Edit form screen
│   │   └── expense_details_modal.dart     # Bottom sheet detail modal
│   ├── analytics/
│   │   └── analytics_screen.dart    # Pie chart and category percentage bars
│   └── settings/
│       └── settings_screen.dart     # Theme toggle, user profile, and disclosures
└── main.dart                        # MultiProvider root and resilient initialization
```

---

## 🛠️ Technologies & Packages Used

| Package | Version | Purpose |
| :--- | :--- | :--- |
| **Flutter & Dart** | SDK >= 3.0.0 | Core mobile framework & language |
| **provider** | `^6.1.2` | Clean, predictable reactive state management |
| **firebase_core** | `^3.6.0` | Firebase initialization & cross-platform core |
| **firebase_auth** | `^5.3.1` | User authentication (Email/Password & Anonymous) |
| **cloud_firestore** | `^5.4.4` | Real-time NoSQL cloud database |
| **fl_chart** | `^0.69.0` | Animated interactive Pie/Donut charts |
| **intl** | `^0.19.0` | Date and currency formatting |
| **shared_preferences** | `^2.3.2` | Local persistent storage for theme preference |
| **uuid** | `^4.5.1` | Unique ID generation |

---

## 🤖 AI Tools Utilization

In compliance with the internship guidelines regarding the effective use of modern AI tools:

- **AI Tools Used**: Google Antigravity & Gemini.
- **How They Helped**:
  1. **Architecture & Schema Design**: Designed a scalable feature-first structure with clean separation between UI, Providers, and Firebase Services.
  2. **Code Quality & Best Practices**: Ensured adherence to modern Flutter Material 3 standards, null-safety, and robust form validation.
  3. **Resilience & Edge Cases**: Formulated fallback mechanisms so the application gracefully handles both live Firebase credentials and offline/demo review mode.
  4. **Documentation**: Generated comprehensive documentation, setup guides, and submission assets.

---

## 🚀 Getting Started & Setup Instructions

### 1. Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (version 3.0.0 or higher)
- Android Studio / VS Code with Flutter extension
- A connected Android device, emulator, or Google Chrome

### 2. Clone the Repository
```bash
git clone https://github.com/YOUR_GITHUB_USERNAME/expense_tracker.git
cd expense_tracker
```

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Firebase Configuration
The app comes ready with Firebase integration. To connect your personal Firebase project:

1. Create a project on the [Firebase Console](https://console.firebase.google.com/).
2. Enable **Authentication** (enable *Email/Password* and *Anonymous* sign-in providers).
3. Enable **Cloud Firestore** and publish the rules from `firestore.rules`:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId}/expenses/{expenseId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```
4. Add your Android app (package name: `com.cyphlab.expense_tracker`) and place the downloaded `google-services.json` in `android/app/google-services.json`.
   *(Or run `flutterfire configure` to generate `lib/firebase_options.dart`).*

> **Note**: Even if Firebase credentials are not yet added, the app includes a fallback demo mode so you can immediately run and test the complete UI and CRUD actions!

### 5. Run the Application
```bash
# Run on connected device or emulator
flutter run

# Or run in Google Chrome
flutter run -d chrome
```

### 6. Build Release APK
```bash
flutter build apk --release
```
The generated APK will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 📱 Application Flow & Screenshots

1. **Authentication Screen**: Clean sign-in / registration with a **"Continue as Guest (Instant Demo)"** button.
2. **Dashboard / Home**: Month selector with total expenses, category filter chips, search bar, and recent transactions.
3. **Add & Edit Expense**: Form with title, amount, category picker, date picker, and note.
4. **Analytics Tab**: Visual donut chart breakdown with percentage distribution for each category.
5. **Settings Tab**: Switch between Dark and Light mode, view account status, and sign out.

---

## 👨‍💻 Developer Information
- **Applicant**: Flutter Developer Intern Candidate
- **Company**: CyphLab (Pvt) Ltd
- **Role**: Mobile App Developer Intern – Flutter
