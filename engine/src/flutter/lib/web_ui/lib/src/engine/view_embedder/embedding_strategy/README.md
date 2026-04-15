# Embedding Strategy

This directory contains the logic for how a Flutter Web application is placed, sized, and measured within the browser's DOM. It provides different strategies for embedding the Flutter view, depending on whether the app should take over the entire page or be contained within a specific element.

## Purpose

The `EmbeddingStrategy` abstract class and its implementations define the interface for:
- Initializing the host element where Flutter will be rendered.
- Attaching the Flutter view's root element to the host.
- Managing global event targets for pointer and keyboard input.
- Updating the page's locale for accessibility and font selection.
- Handling necessary CSS styles and meta tags for the embedding mode.

## Files

- **`embedding_strategy.dart`**: Defines the `EmbeddingStrategy` abstract class, which provides a common interface for all embedding strategies. It includes a factory method, `EmbeddingStrategy.create`, to instantiate the appropriate strategy based on whether a host element is provided.
- **`custom_element_embedding_strategy.dart`**: Implements `CustomElementEmbeddingStrategy`, which renders the Flutter view inside a specific host element provided by the developer. This strategy is designed to be "non-invasive," minimizing DOM modifications outside the designated host to coexist with other web frameworks.
- **`full_page_embedding_strategy.dart`**: Implements `FullPageEmbeddingStrategy`, the default behavior where Flutter takes over the entire web page. It manages the `<body>` element's styles and sets the appropriate viewport meta tags to ensure correct rendering and interaction in full-screen mode.
