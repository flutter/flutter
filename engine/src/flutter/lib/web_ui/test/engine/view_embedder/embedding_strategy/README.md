# Embedding Strategy Tests

This directory contains tests for the various strategies Flutter Web uses to embed its engine into a web page. These strategies determine how the Flutter application is attached to the DOM and how it interacts with the host environment (e.g., full page vs. inside a specific element).

## Files

- **`embedding_strategy_test.dart`**: Tests the `EmbeddingStrategy` factory method. It ensures that the correct strategy instance (`FullPageEmbeddingStrategy` or `CustomElementEmbeddingStrategy`) is created based on whether a host element is provided.
- **`full_page_embedding_strategy_test.dart`**: Verifies the behavior of the `FullPageEmbeddingStrategy`. This includes ensuring it correctly initializes the page environment (like setting up viewport meta tags) and attaches the glasspane to cover the entire browser viewport.
- **`custom_element_embedding_strategy_test.dart`**: Verifies the behavior of the `CustomElementEmbeddingStrategy`. This includes ensuring it correctly identifies the target element and attaches the glasspane so that it fills the dimensions of the provided host element.
