// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

/// An enum identifying standard UI components.
///
/// This enum is used to attach a key to a widget identifying it as a standard
/// UI component for testing and discovery purposes.
///
/// It is used by the testing infrastructure (e.g. the `find` object in the
/// Flutter test framework) to positively identify and/or activate specific
/// widgets as representing standard UI components, since many of these
/// components vary slightly in the icons or tooltips that they use, and making
/// an effective test matcher for them is fragile and error prone.
///
/// The keys don't have any effect on the functioning of the UI elements, they
/// are just a means of identifying them. A widget won't be treated specially if
/// it has this key, other than to be found by the testing infrastructure. If
/// tests are not searching for them, then adding them to a widget serves no
/// purpose.
///
/// Any widget with the [key] from a value here applied to it will be considered
/// to be that type of standard UI component in tests.
///
/// Types included here are generally only those for which it can be difficult
/// or fragile to create a reliable test matcher for. It is not (nor should it
/// become) an exhaustive list of standard UI components.
///
/// These are typically used in tests via `find.backButton()` or
/// `find.closeButton()`.
enum StandardComponentType {
  /// Indicates the associated widget is a standard back button, typically used
  /// to navigate back to the previous screen.
  backButton,

  /// Indicates the associated widget is a close button, typically used to
  /// dismiss a dialog or modal sheet.
  closeButton,

  /// Indicates the associated widget is a "more" button, typically used to
  /// display a menu of additional options.
  moreButton,

  /// Indicates the associated widget is a drawer button, typically used to open
  /// a drawer.
  drawerButton;

  /// Returns a [ValueKey] for this [StandardComponentType].
  ///
  /// Attach this key to a widget to indicate it is a standard UI component.
  ValueKey<StandardComponentType> get key => ValueKey<StandardComponentType>(this);
}
