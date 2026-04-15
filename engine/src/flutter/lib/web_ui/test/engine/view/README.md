# Engine View Tests

This directory contains unit tests for the engine's view-related logic. These tests ensure that the engine correctly handles view-level constraints, sizing, and interaction with the platform (e.g., JavaScript).

## Files

- **`view_constraints_test.dart`**: Tests the `ViewConstraints` class and its `fromJs` factory. It verifies that constraints passed from JavaScript are correctly parsed, validated (e.g., no negative or infinite minimums), and that default behaviors (like tightening to the current size when constraints are missing) work as expected.
