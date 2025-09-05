# AI rules for Flutter

You are an expert in Flutter and Dart development. Your goal is to build
beautiful, performant, and maintainable applications following modern best
practices.

## Project Structure
*   Assumes a standard Flutter project structure with `lib/main.dart` as the
    primary application entry point.

## Package Management
*   If a new feature requires an external package, the AI will identify the most
    suitable and stable package from pub.dev.
*   To add a regular dependency, it will execute `flutter pub add
    <package_name>`.
*   To add a development dependency, it will execute `flutter pub add
    dev:<package_name>`.

## Code Quality
*   Adhere to maintainable code structure and separation of concerns (e.g., UI
    logic separate from business logic).
*   Adhere to meaningful and consistent naming conventions.

## Dart Best Practices
*   Follow the official Effective Dart guidelines.
*   Define related classes within the same library file. For large libraries,
    export smaller, private libraries from a single top-level library.
*   Group related libraries in the same folder.
*   Add documentation comments to all public APIs, including classes,
    constructors, methods, and top-level functions.
*   Write clear comments for complex or non-obvious code. Avoid over-commenting.
*   Don't add trailing comments.
*   Ensure proper use of `async`/`await` for asynchronous operations with robust
    error handling.
*   Use pattern matching features where they simplify the code.

## Flutter Best Practices
*   Widgets (especially `StatelessWidget`) are immutable; when the UI needs to
    change, Flutter rebuilds the widget tree.
*   Prefer composing smaller widgets over extending existing ones.
*   Use small, private `Widget` classes instead of private helper methods that
    return a `Widget`.
*   Break down large `build()` methods into smaller, reusable private Widget
    classes.
*   Use `ListView.builder` to create lazy-loaded lists for performance.
*   Use `const` constructors for widgets and in `build()` methods whenever
    possible to optimize performance.
*   Avoid performing expensive operations, like network calls or complex
    computations, directly within `build()` methods.

## Application Architecture
*   Aim for separation of concerns similar to MVC/MVVM, with defined Model,
    View, and ViewModel/Controller roles.

### State Management
*   Default to Flutter's built-in state management solutions. Do not use a
    third-party package unless explicitly requested.
*   Use `Streams` and `StreamBuilder` for handling a sequence of asynchronous
    events.
*   Use `Futures` and `FutureBuilder` for handling a single asynchronous
    operation that will complete in the future.
*   Use `ValueNotifier` with `ValueListenableBuilder` for simple, local state
    that involves a single value.

```dart
// Define a ValueNotifier to hold the state.
final ValueNotifier<int> _counter = ValueNotifier<int>(0);

// Use ValueListenableBuilder to listen and rebuild.
ValueListenableBuilder<int>(
  valueListenable: _counter,
  builder: (context, value, child) {
    return Text('Count: $value');
  },
);
```

*   For state that is more complex or shared across multiple widgets, use
    `ChangeNotifier`.
*   Use `ListenableBuilder` to listen to changes from a `ChangeNotifier` or
    other `Listenable`.
*   When a more robust solution is needed, structure the app using the
    Model-View-ViewModel (MVVM) pattern.
*   Use manual dependency injection via constructors to make a class's
    dependencies explicit in its API.
*   Use `provider` for dependency injection to make services, repositories, or
    complex state objects available to the UI layer without tight coupling
    (note: `new-rules.md` generally defaults against third-party packages for
    state management unless explicitly requested).

### Data Flow
*   Define data structures (classes) to represent the data used in the
    application.
*   Abstract data sources (e.g., API calls, database operations) using
    Repositories/Services to promote testability.

### Routing
*   Use `go_router` for declarative navigation, deep linking, and web support.

    ```dart
    // 1. Add the dependency
    // flutter pub add go_router
    
    // 2. Configure the router
    final GoRouter _router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
          routes: <RouteBase>[
            GoRoute(
              path: 'details/:id', // Route with a path parameter
              builder: (context, state) {
                final String id = state.pathParameters['id']!;
                return DetailScreen(id: id);
              },
            ),
          ],
        ),
      ],
    );
    
    // 3. Use it in your MaterialApp
    MaterialApp.router(
      routerConfig: _router,
    );
    ```

*   Use the built-in `Navigator` for short-lived screens that do not need to be
    deep-linkable, such as dialogs or temporary views.

    ```dart
    // Push a new screen onto the stack
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DetailsScreen()),
    );
    
    // Pop the current screen to go back
    Navigator.pop(context);
    ```

### Data Handling & Serialization
*   Use `json_serializable` and `json_annotation` for parsing and encoding JSON
    data.
*   When encoding data, use `fieldRename: FieldRename.snake` to convert Dart's
    camelCase fields to snake_case JSON keys.

    ```dart
    // In your model file
    import 'package:json_annotation/json_annotation.dart';
    
    part 'user.g.dart';
    
    @JsonSerializable(fieldRename: FieldRename.snake)
    class User {
      final String firstName;
      final String lastName;
    
      User({required this.firstName, required this.lastName});
    
      factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
      Map<String, dynamic> toJson() => _$UserToJson(this);
    }
    ```

### Logging
*   Use the `log` function from `dart:developer` for structured logging that
    integrates with Dart DevTools.

    ```dart
    import 'dart:developer' as developer;
    
    // For simple messages
    developer.log('User logged in successfully.');
    
    // For structured error logging
    try {
      // ... code that might fail
    } catch (e, s) {
      developer.log(
        'Failed to fetch data',
        name: 'myapp.network',
        level: 1000, // SEVERE
        error: e,
        stackTrace: s,
      );
    }
    ```

## Error Handling
*   Implement mechanisms to gracefully handle errors across the application
    (e.g., using try-catch blocks, Either types for functional error handling,
    or global error handlers).

## Code Generation
*   Use `build_runner` for all code generation tasks, such as for
    `json_serializable`.
*   After modifying files that require code generation, run the build command:

    ```shell
    dart run build_runner build --delete-conflicting-outputs
    ```

## Testing
*   Use `package:test` for unit tests.
*   Use `package:flutter_test` for widget tests.
*   Use `package:integration_test` for integration tests.
*   Prefer using `package:checks` for more expressive and readable assertions
    over the default `matchers`.

## Visual Design & Theming
*   Build beautiful and intuitive user interfaces that follow modern design
    guidelines.
*   Ensure the app is mobile responsive and adapts to different screen sizes,
    working perfectly on mobile and web.
*   If there are multiple pages for the user to interact with, provide an
    intuitive and easy navigation bar or controls.
*   Stress and emphasize font sizes to ease understanding, e.g., hero text,
    section headlines, list headlines, keywords in paragraphs.
*   Apply subtle noise texture to the main background to add a premium, tactile
    feel.
*   Multi-layered drop shadows create a strong sense of depth; cards have a
    soft, deep shadow to look "lifted."
*   Incorporate icons to enhance the user’s understanding and the logical
    navigation of the app.
*   Buttons, checkboxes, sliders, lists, charts, graphs, and other interactive
    elements have a shadow with elegant use of color to create a "glow" effect.

### Theming
*   Define a centralized `ThemeData` object to ensure a consistent
    application-wide style.
*   Use Material 3 by setting `useMaterial3: true` in your `ThemeData`.
*   Implement support for both light and dark themes, ideal for a user-facing
    theme toggle (`ThemeMode.light`, `ThemeMode.dark`, `ThemeMode.system`).
*   Generate harmonious color palettes from a single color using
    `ColorScheme.fromSeed`.

    ```dart
    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      // ... other theme properties
    );
    ```
*   Include a wide range of color concentrations and hues in the palette to
    create a vibrant and energetic look and feel.
*   Use specific theme properties (e.g., `appBarTheme`, `elevatedButtonTheme`)
    to customize the appearance of individual Material components.
*   For custom fonts, use the `google_fonts` package. Define a `TextTheme` to
    apply fonts consistently.

    ```dart
    // 1. Add the dependency
    // flutter pub add google_fonts
    
    // 2. Define a TextTheme with a custom font
    final TextTheme appTextTheme = TextTheme(
      displayLarge: GoogleFonts.oswald(fontSize: 57, fontWeight: FontWeight.bold),
      titleLarge: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.openSans(fontSize: 14),
    );
    ```

### Assets and Images
*   If images are needed, make them relevant and meaningful, with appropriate
    size, layout, and licensing (e.g., freely available). Provide placeholder
    images if real ones are not available.
*   Declare all asset paths in your `pubspec.yaml` file.

    ```yaml
    flutter:
      uses-material-design: true
      assets:
        - assets/images/
    ```

*   Use `Image.asset` to display local images from your asset bundle.

    ```dart
    Image.asset('assets/images/placeholder.png')
    ```

*   Displays an icon from an `ImageProvider`, useful for custom icons not in
    `Icons` class.
*   Use `Image.network` to display images from a URL, and always include
    `loadingBuilder` and `errorBuilder` for a better user experience.

    ```dart
    Image.network(
      'https://picsum.photos/200/300',
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.error);
      },
    )
    ```

## Accessibility (A11Y)
*   Implement accessibility features to empower all users, assuming a wide
    variety of users with different physical abilities, mental abilities, age
    groups, education levels, and learning styles.
