// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'theme.dart';
import 'icon_button.dart';
import 'icon.dart';
import 'icons.dart';

/// A material design back button.
///
/// A [BackButton] is an [IconButton] with a "back" icon appropriate for the
/// current [TargetPlatform]. When pressed, the back button calls
/// [Navigator.maybePop] to return to the previous route.
///
/// When deciding to display a [BackButton], consider using
/// `ModalRoute.of(context)?.canPop` to check whether the current route can be
/// popped. If that value is false (e.g., because the current route is the
/// initial route), the [BackButton] will not have any effect when pressed,
/// which could frustrate the user.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [AppBar], which automatically uses a [BackButton] in its
///    [AppBar.leading] slot when appropriate.
///  * [IconButton], which is a more general widget for creating buttons with
///    icons.
class BackButton extends StatelessWidget {
  /// Creates an [IconButton] with the appropriate "back" icon for the current
  /// target platform.
  const BackButton({ Key key }) : super(key: key);

  /// Returns tha appropriate "back" icon for the given `platform`.
  static IconData getIconData(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return Icons.arrow_back;
      case TargetPlatform.iOS:
        return Icons.arrow_back_ios;
    }
    assert(false);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return new IconButton(
      icon: new Icon(getIconData(Theme.of(context).platform)),
      tooltip: 'Back', // TODO(ianh): Figure out how to localize this string
      onPressed: Navigator.of(context).maybePop,
    );
  }
}
