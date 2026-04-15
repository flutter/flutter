# Services

This directory contains the serialization and messaging infrastructure for the Flutter Web Engine. These services enable communication between the engine and the Flutter framework/plugins using various data formats.

## Files

- **`buffers.dart`**: Provides growable typed data buffers (e.g., `Uint8Buffer`) that are optimized for binary data manipulation and efficient memory usage.
- **`message_codec.dart`**: Defines the core abstractions for message encoding and decoding, including base classes like `MessageCodec`, `MethodCodec`, and `MethodCall`, along with standard platform exceptions.
- **`message_codecs.dart`**: Contains concrete implementations of various serialization formats, such as Binary, String, JSON, and the Flutter Standard Binary format.
- **`serialization.dart`**: Provides `WriteBuffer` and `ReadBuffer` utilities for the incremental construction and sequential parsing of binary messages (`ByteData`).
