# Engine Services Tests

This directory contains unit tests for the serialization and messaging infrastructure of the Flutter Web Engine. These tests ensure the reliability of the communication channel between the engine and the Flutter framework/plugins.

## Files

- **`serialization_test.dart`**: Verifies the correctness of the `WriteBuffer` and `ReadBuffer` utilities used for incremental construction and sequential parsing of binary messages (`ByteData`). It ensures that various data types (single bytes, 32-bit/64-bit integers, doubles, and typed data lists) can be correctly serialized and deserialized in a round-trip fashion, including checks for unaligned memory access.
