// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'framework.dart';
import 'media_query.dart';

/// A widget that can optionally avoid refreshing [MediaQueryData] that delivered
/// to subtree when parent [MediaQueryData] dependency has changed.
/// This can prevent subtree from being rebuilt when unnecessary.
class MediaQueryRefreshMode extends StatefulWidget {
  /// The [enabled] and [child] arguments must not be null.
  const MediaQueryRefreshMode({
    super.key,
    this.enabled = true,
    required this.child,
  });

  /// Enables or disables to refresh the [MediaQueryData] delivered to subtree.
  ///
  /// Default is true. If set false, when parent update [MediaQueryData], the refresh signal
  /// will not deliver to subtree, so the subtree will not rebuild.
  final bool enabled;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  State<MediaQueryRefreshMode> createState() => _MediaQueryRefreshModeState();
}

class _MediaQueryRefreshModeState extends State<MediaQueryRefreshMode> {
  // The _ancestorMediaQueryData is always up-to-date.
  MediaQueryData? _ancestorMediaQueryData;

  MediaQueryData? _currentMediaQueryData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ancestorMediaQueryData = MediaQuery.maybeOf(context);
    _currentMediaQueryData ??= _ancestorMediaQueryData;
    _updateCurrentMediaQueryData();
  }

  @override
  void didUpdateWidget(covariant MediaQueryRefreshMode oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateCurrentMediaQueryData();
  }

  void _updateCurrentMediaQueryData() {
    if (widget.enabled) {
      _currentMediaQueryData = _ancestorMediaQueryData;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentMediaQueryData == null) {
      return widget.child;
    }
    return MediaQuery(data: _currentMediaQueryData!, child: widget.child);
  }
}
