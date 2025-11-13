# Flutter Style Guide

This style guide outlines the coding conventions for contributions to the
flutter/flutter repository. It is based on the more comprehensive official
[style guide for the Flutter repository](https://github.com/flutter/flutter/blob/main/docs/contributing/Style-guide-for-Flutter-repo.md).

## Best Practices

- Code should follow the guidance and principles described in
  [the Flutter contribution guide](https://github.com/flutter/flutter/blob/main/CONTRIBUTING.md).
- Code should be tested and follow the guidance described in the [writing effective tests guide](https://github.com/flutter/flutter/blob/main/docs/contributing/testing/Writing-Effective-Tests.md) and the [running and writing tests guide](https://github.com/flutter/flutter/blob/main/docs/contributing/testing/Running-and-writing-tests.md).
- Changes to the [engine/ directory](https://github.com/flutter/flutter/tree/main/engine) should additionally have appropriate tests as described in [the engine test guidance](https://github.com/flutter/flutter/blob/main/docs/engine/testing/Testing-the-engine.md).
- PR descriptions should include the Pre-launch Checklist from
  [the PR template](https://github.com/flutter/flutter/blob/main/.github/PULL_REQUEST_TEMPLATE.md),
  with all of the steps completed.
- The most relevant guidelines should take precedence over less relevant
  guidelines. For Flutter code, the
  [Flutter styleguide](https://github.com/flutter/flutter/blob/main/docs/contributing/Style-guide-for-Flutter-repo.md)
  should be followed as the first priority, and
  [Effective Dart: Style](https://dart.dev/effective-dart/style)
  should only be followed when it does not conflict with the former.

## Review Agent Guidelines

- Only review changes to the `master` branch. Other changes have already been reviewed (and are being cherrypicked).

## General Philosophy

- **Optimize for readability**: Code is read more often than it is written.
- **Avoid duplicating state**: Keep only one source of truth.
- Write what you need and no more, but when you write it, do it right.
- **Error messages should be useful**: Every error message is an opportunity to make someone love our product.

## Dart Formatting

- All Dart code is formatted using `dart format`. This is enforced by CI.
- Constructors come first in a class definition, with the default constructor preceding named constructors.
- Other class members should be ordered logically (e.g., by lifecycle, or grouping related fields and methods).

## Miscellaneous Languages

- Python code is formatted using `yapf`, linted with `pylint`, and should follow the [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html).
- C++ code is formatted using `clang-format`, linted with `clang-tidy`, and should follow the [Google C++ Style Guide](https://google.github.io/styleguide/cppguide.html).
- Shaders are formatted using `clang-format`.
- Kotlin code is formatted using `ktformat`, linted with `ktlint`, and should follow the [Android Kotlin Style Guide](https://developer.android.com/kotlin/style-guide).
- Java code is formatted using `google-java-format` and should follow the [Google Java Style Guide](https://google.github.io/styleguide/javaguide.html).
- Objective-C is formatted using `clang-format`, linted with `clang-tidy`, and should follow the [Google Objective-C Style Guide](https://google.github.io/styleguide/objcguide.html).
- Swift is formatted and linted using `swift-format` and should follow the [Google Swift Style Guide](https://google.github.io/swift).
- GN code is formatted using `gn format` and should follow the [GN Style Guide](https://gn.googlesource.com/gn/+/main/docs/style_guide.md).

## Documentation

- All public members should have documentation.
- **Answer your own questions**: If you have a question, find the answer, and then document it where you first looked.
- **Documentation should be useful**: Explain the *why* and the *how*.
- **Introduce terms**: Assume the reader does not know everything. Link to definitions.
- **Provide sample code**: Use `{@tool dartpad}` for runnable examples.
  - Inline code samples are contained within `{@tool dartpad}` and `{@end-tool}`, and use the format of the following example to insert the code sample:
    - `/// ** See code in examples/api/lib/widgets/sliver/sliver_list.0.dart **`
    - Do not confuse this format with `/// See also:` sections of the documentation, which provide helpful breadcrumbs to developers.
- **Provide illustrations or screenshots** for widgets.
- Use `///` for public-quality documentation, even on private members.

## Review Agent Guidelines

When providing a summary, the review agent must adhere to the following principles:
- **Be Objective:** Focus on a neutral, descriptive summary of the changes. Avoid subjective value judgments
  like "good," "bad," "positive," or "negative." The goal is to report what the code does, not to evaluate it.
- **Use Code as the Source of Truth:** Base all summaries on the code diff. Do not trust or rephrase the PR
  description, which may be outdated or inaccurate. A summary must reflect the actual changes in the code.
- **Be Concise:** Generate summaries that are brief and to the point. Focus on the most significant changes,
  and avoid unnecessary details or verbose explanations. This ensures the feedback is easy to scan and understand.

## Further Reading

For more detailed guidance, refer to the following documents:

- [Style guide for the Flutter repository](https://github.com/flutter/flutter/blob/main/docs/contributing/Style-guide-for-Flutter-repo.md)
- [Effective Dart: Style](https://dart.dev/effective-dart/style)
- [Tree Hygiene](https://github.com/flutter/flutter/blob/main/docs/contributing/Tree-hygiene.md)
- [The Flutter contribution guide](https://github.com/flutter/flutter/blob/main/CONTRIBUTING.md)
- [Writing effective tests guide](https://github.com/flutter/flutter/blob/main/docs/contributing/testing/Writing-Effective-Tests.md)
- [Running and writing tests guide](https://github.com/flutter/flutter/blob/main/docs/contributing/testing/Running-and-writing-tests.md)
- [Engine testing guide](https://github.com/flutter/flutter/blob/main/docs/engine/testing/Testing-the-engine.md)
