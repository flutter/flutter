# Common Test Utilities

This directory contains shared utilities, mocks, and helper classes used across the Flutter Web Engine's test suite. These tools facilitate simulating engine behavior, mocking external dependencies, and providing custom assertions to ensure the correctness of the engine's implementation.

## Files

- **`fake_asset_manager.dart`**: Implements a mock asset manager and scoping mechanism to simulate loading assets (such as fonts and manifests) without requiring a real server or file system.
- **`keyboard_test_common.dart`**: Provides a `MockKeyboardEvent` class that simulates browser keyboard events, allowing tests to verify keyboard input handling and modifier key states.
- **`matchers.dart`**: A collection of custom `test` package matchers. It includes `within` for fuzzy equality of geometric types (Colors, Offsets, Rects), `hasHtml` for structural DOM verification against patterns, and `throwsAssertionError`.
- **`rendering.dart`**: Utilities for driving the engine's rendering pipeline during tests, enabling manual frame triggering and scene rendering.
- **`spy.dart`**: Contains "spy" objects like `PlatformMessagesSpy` and `ZoneSpy` to intercept and inspect communication between the engine and the framework, or to monitor asynchronous activity and print logs.
- **`test_data.dart`**: A repository of constant byte arrays representing various image formats (PNG, animated GIF) used as sample data for image-related tests.
- **`test_initialization.dart`**: Provides common setup and teardown logic for unit tests, including engine bootstrapping, environment configuration, and default view/display management.
