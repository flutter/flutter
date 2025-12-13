// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is used by ../analyze_snippet_code_test.dart to test detection
// of preamble declarations that are used in docstring examples.
// This tests the fix for false positives where variables used in docstring
// examples (not in {@tool snippet} blocks) were incorrectly flagged as unused.

// Examples can assume:
// bool _isDrawerOpen = false;
// int _selectedIndex = 0;

/// Widget example that uses preamble declarations.
///
/// For example, in a stateful widget you might have:
///
/// ```dart
/// _SelectableAnimatedBuilder(
///   isSelected: _isDrawerOpen,
///   builder: (context, animation) {
///     return AnimatedIcon(
///       icon: AnimatedIcons.menu_arrow,
///       progress: animation,
///       semanticLabel: 'Show menu',
///     );
///   }
/// )
/// ```
///
/// This example demonstrates the use of [_isDrawerOpen] and other preamble items.
class ExampleWidget {}

/// Another class that references the preamble in documentation.
///
/// The [_selectedIndex] variable can be used like:
///
/// ```dart
/// if (_selectedIndex == 0) {
///   print('Home page selected');
/// }
/// ```
class AnotherExample {}
