// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic.dart';
import 'framework.dart';
import 'page_storage.dart';
import 'ticker_provider.dart';
import 'transitions.dart';

///
mixin ExpansibleStateMixin<S extends StatefulWidget> on TickerProviderStateMixin<S> {
  late AnimationController _animationController;

  bool _isExpanded = false;

  ///
  ValueChanged<bool>? get onExpansionChanged;

  ///
  bool get isExpanded => _isExpanded;

  ///
  AnimationController get animationController => _animationController;

  ///
  EdgeInsetsGeometry get childrenPadding => EdgeInsets.zero;

  ///
  bool get maintainState => false;

  ///
  List<Widget> get children;

  ///
  CrossAxisAlignment get expandedCrossAxisAlignment => CrossAxisAlignment.center;

  ///
  Duration get expansionDuration;

  ///
  bool get initiallyExpanded;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: expansionDuration, vsync: this);
    _isExpanded = PageStorage.maybeOf(context)?.readState(context) as bool? ?? initiallyExpanded;
    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @protected
  @mustCallSuper
  ///
  void toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse().then<void>((void value) {
          if (!mounted) {
            return;
          }
          setState(() {
            // Rebuild without widget.children.
          });
        });
      }
      PageStorage.maybeOf(context)?.writeState(context, _isExpanded);
    });
    onExpansionChanged?.call(_isExpanded);
  }

  ///
  Widget buildChildren(BuildContext context, Widget? child);

  @override
  Widget build(BuildContext context) {
    final bool closed = !isExpanded && animationController.isDismissed;
    final bool shouldRemoveChildren = closed && !maintainState;

    final Widget result = Offstage(
      offstage: closed,
      child: TickerMode(
        enabled: !closed,
        child: Padding(
          padding: childrenPadding,
          child: Column(crossAxisAlignment: expandedCrossAxisAlignment, children: children),
        ),
      ),
    );

    return AnimatedBuilder(
      animation: animationController.view,
      builder: buildChildren,
      child: shouldRemoveChildren ? null : result,
    );
  }
}
