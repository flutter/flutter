// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


/// Specifies the sensitivity level that a [SensitiveContent] widget should
/// set for the Flutter app screen on Android.
// TODO(camsim99): Implement `autoSensitive` mode that will attempt to match
// the behavior of `CONTENT_SENSITIVITY_AUTO` on Android that has implemented
// based on autofill hints.
// TODO(camsim99): File issue for implementing `autoSensitive` mode.
enum ContentSensitivity {
  /// The screen does not display sensitive content.
  /// 
  /// See https://developer.android.com/reference/android/view/View#CONTENT_SENSITIVITY_NOT_SENSITIVE.
  notSensitive,
  
  /// The screen displays sensitive content and the window hosting the screen
  /// will be marked as secure during an active media projection session.
  /// 
  /// See https://developer.android.com/reference/android/view/View#CONTENT_SENSITIVITY_NOT_SENSITIVE.
  sensitive,
}

/// A widget that sets the sensitivity of the Flutter app screen.
/// 
/// Currently this is a no-op on non-Android platforms.
class SensitiveContent extends StatefulWidget {
  /// Creates a widget that sets the sensitivity of the Flutter app
  /// screen.
  ///
  /// This widget does nothing on non-Android platforms.
  SensitiveContent({
    super.key,
    this.sensitivityLevel = ContentSensitivity.sensitive,
    this.child,
  });

  /// The sensitivity level of that the [SensitiveContent] widget should set.
  final ContentSensitivity sensitivityLevel;

  /// The child widget of this [SensitiveContent].
  ///
  /// If the [sensitivtyLevel] is set to [ContentSensitivity.sensitive], then
  /// the entire screen will be obscured when the screen is project regardless
  /// of the parent/child widgets.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  @override
  State<SensitiveContent> createState() => _SensitiveContentState();
}

class _SensitiveContentState extends State<SensitiveContent> {
  @override
  void initState() {
    super.initState();

    // Make call to native to mark appropriate content sensitivity.
    // CAMILLE: write a mock example though
    // TODO(camsim99): Figure out how to make this call with jni-generated code.
  }

  @override
  void dispose() {
    // Check the current content sensitivity mode. If it is different than the mode
    // set by this widget, then we assume it must have been chang
    ContentSensitivity currentContentSensitivity = SensitiveContentUtils.getCurrentContentSensitivity();


    super.dispose();
  }

  /// Check if we should make a native call to set the content sensitivity.
  /// 
  /// The mode should only be set if it does not override the most severe
  /// [ContentSensitivity] mode set by other [SensitivecContent] widgts in the
  /// tree.
  bool _shouldSetContentSensitivity() {
    // Determine if there are any other sensitive  content widgets.
    // CAMILLE: I'm here!!!! think i need to take a stateful widget + inherited widget approach here!
  }

  @override
  Widget build(BuildContext context) => widget.child;
}