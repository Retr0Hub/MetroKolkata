# Architecture 🏗️

This document outlines the architecture and design patterns used in the MetroKolkata Flutter application.

## 🎯 Architecture Overview

MetroKolkata follows a **layered architecture** with clear separation of concerns, making the codebase maintainable, testable, and scalable.

```
┌─────────────────────────────────────┐
│              UI Layer               │
│         (Screens & Widgets)         │
├─────────────────────────────────────┤
│           State Management          │
│            (Provider)               │
├─────────────────────────────────────┤
│            Service Layer            │
│      (Firebase, Google Maps)       │
├─────────────────────────────────────┤
│             Data Layer              │
│         (Models & Local)            │
└─────────────────────────────────────┘
```

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point
├── auth_wrapper.dart           # Authentication wrapper
├── theme.dart                  # App themes
├── theme_provider.dart         # Theme state management
├── app_theme.dart             # Extended theme definitions
├── firebase_options.dart      # Firebase configuration
├── models/                    # Data models
│   ├── metro_data.dart
│   └── metro_station.dart
├── screens/                   # UI screens
│   ├── auth_decision_screen.dart
│   ├── auth_screen.dart
│   ├── create_profile_screen.dart
│   ├── forgot_password_screen.dart
│   ├── home_screen.dart
│   ├── login_screen.dart
│   ├── phone_auth_screen.dart
│   ├── plan_journey_screen.dart
│   ├── profile_screen.dart
│   ├── recharge_screen.dart
│   ├── tickets_screen.dart
│   └── verify_email_screen.dart
├── shared/                    # Shared components
│   └── app_decorations.dart
└── assets/                    # Static assets
    ├── images/
    ├── icons/
    └── data/
```

## 🏛️ Architectural Layers

### 1. Presentation Layer (UI)

**Responsibility**: User interface and user interaction handling

#### Components:
- **Screens**: Full-page views that represent different app states
- **Widgets**: Reusable UI components
- **Themes**: Visual styling and branding

#### Key Files:
- `lib/screens/` - All screen implementations
- `lib/theme.dart` - App-wide theming
- `lib/shared/` - Reusable UI components

#### Design Patterns:
- **Widget Composition**: Building complex UIs from simple widgets
- **Material Design 3**: Following Google's design guidelines
- **Responsive Design**: Adapting to different screen sizes

### 2. State Management Layer

**Responsibility**: Managing application state and business logic

#### Technology: Provider Pattern

```dart
// Example: ThemeProvider
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode => _themeMode;
  
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
    _saveThemeToPrefs(mode);
  }
}
```

#### Key Features:
- **ChangeNotifier**: For reactive state updates
- **Consumer Widgets**: For selective UI rebuilds
- **Provider.of**: For accessing state across the widget tree

### 3. Service Layer

**Responsibility**: External service integration and business logic

#### Services:
- **Firebase Authentication**: User login/signup
- **Cloud Firestore**: Real-time data storage
- **Google Maps**: Map integration and location services
- **Google Sign-In**: Social authentication

#### Key Integrations:
```dart
// Firebase initialization
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### 4. Data Layer

**Responsibility**: Data models and local storage

#### Models:
```dart
class MetroStation {
  final String name;
  final double latitude;
  final double longitude;
  
  const MetroStation({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}
```

#### Data Sources:
- **Cloud Firestore**: Remote data storage
- **SharedPreferences**: Local preferences
- **JSON Assets**: Static metro data

## 🔄 Data Flow

### Authentication Flow
```
User Input → AuthScreen → Firebase Auth → AuthWrapper → HomeScreen
     ↓
SharedPreferences ← ThemeProvider ← AuthState
```

### Map Integration Flow
```
User Location → Geolocator → Google Maps → MetroStation Models
     ↓
UI Updates ← Provider ← Firestore ← Map Markers
```

## 🎨 Design Patterns

### 1. Provider Pattern (State Management)
```dart
ChangeNotifierProvider(
  create: (_) => ThemeProvider(),
  child: Consumer<ThemeProvider>(
    builder: (context, themeProvider, child) {
      return MaterialApp(
        themeMode: themeProvider.themeMode,
        // ...
      );
    },
  ),
)
```

### 2. Singleton Pattern (Services)
```dart
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();
}
```

### 3. Factory Pattern (Model Creation)
```dart
class MetroData {
  static MetroStation fromJson(Map<String, dynamic> json) {
    return MetroStation(
      name: json['name'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }
}
```

## 📱 Screen Architecture

### Screen Structure Pattern
```dart
class ExampleScreen extends StatefulWidget {
  @override
  _ExampleScreenState createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  // State variables
  
  @override
  void initState() {
    super.initState();
    // Initialization
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // UI implementation
    );
  }
  
  // Helper methods
}
```

### Navigation Architecture
```dart
// Declarative navigation
Navigator.pushNamed(context, '/home');

// Route definitions in MaterialApp
routes: {
  '/': (context) => AuthWrapper(),
  '/home': (context) => HomeScreen(),
  '/profile': (context) => ProfileScreen(),
}
```

## 🔐 Security Architecture

### Authentication Security
- **Firebase Auth**: Secure user authentication
- **Google Sign-In**: OAuth 2.0 integration
- **Token Management**: Automatic token refresh
- **Session Management**: Persistent login state

### Data Security
- **Firestore Rules**: Server-side data validation
- **API Key Security**: Environment-based configuration
- **Local Storage**: Encrypted preferences

## 🎯 State Management Strategy

### Provider Implementation
```dart
// main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => MapProvider()),
  ],
  child: MyApp(),
)
```

### State Scope Management
- **Global State**: Theme, Authentication
- **Screen State**: Local UI state
- **Widget State**: Component-specific state

## 🚀 Performance Optimizations

### Widget Optimization
- **const Constructors**: Immutable widgets
- **Builder Widgets**: Minimize rebuilds
- **Selective Listeners**: Consumer vs Selector

### Memory Management
- **Dispose Pattern**: Proper resource cleanup
- **Stream Subscriptions**: Managed lifecycles
- **Image Caching**: Optimized asset loading

### Network Optimization
- **Firestore Caching**: Offline-first approach
- **Lazy Loading**: On-demand data fetching
- **Compression**: Optimized asset delivery

## 🧪 Testing Architecture

### Testing Strategy
```
Unit Tests → Widget Tests → Integration Tests
     ↓              ↓              ↓
  Models       UI Components   User Flows
```

### Test Structure
```dart
// Example unit test
testWidgets('Theme toggle works', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());
  await tester.tap(find.byIcon(Icons.brightness_6));
  await tester.pump();
  // Verify theme change
});
```

## 📦 Dependency Management

### Core Dependencies
- **flutter**: Framework
- **firebase_core**: Firebase SDK
- **provider**: State management
- **google_maps_flutter**: Maps integration

### Development Dependencies
- **flutter_test**: Testing framework
- **flutter_lints**: Code analysis

## 🔧 Build Architecture

### Build Configurations
```yaml
# pubspec.yaml
flutter:
  assets:
    - lib/assets/
  uses-material-design: true
```

### Platform-Specific Builds
- **Android**: Gradle build system
- **iOS**: Xcode project
- **Web**: Dart2JS compilation

## 🚀 Deployment Architecture

### CI/CD Pipeline
```
Code Push → GitHub Actions → Build → Test → Deploy
     ↓              ↓          ↓      ↓       ↓
  Repository    Automated   APK/IPA  Unit   Web/Store
               Testing     Build    Tests   Deployment
```

## 📚 Best Practices

### Code Organization
- **Feature-based Structure**: Group related files
- **Clear Naming**: Descriptive file and class names
- **Single Responsibility**: One concern per class

### State Management
- **Immutable State**: Avoid direct state mutation
- **Granular Updates**: Minimize rebuild scope
- **Error Handling**: Proper error state management

### Performance
- **Widget Rebuilds**: Optimize with const and keys
- **Memory Leaks**: Dispose resources properly
- **Bundle Size**: Tree-shake unused code

---

*This architecture ensures maintainability, scalability, and performance while following Flutter best practices.*