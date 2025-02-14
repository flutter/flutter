// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic.dart';
import 'framework.dart';
import 'page_storage.dart';
import 'ticker_provider.dart';
import 'transitions.dart';

///
class ExpansibleController<S extends StatefulWidget> {
  ExpansibleStateMixin<S>? _state;

  ///
  bool get isExpanded {
    assert(_state != null);
    return _state!.isExpanded;
  }

  ///
  void expand() {
    assert(_state != null);
    if (!isExpanded) {
      _state!.toggleExpansion();
    }
  }

  ///
  void collapse() {
    assert(_state != null);
    if (isExpanded) {
      _state!.toggleExpansion();
    }
  }
}

///
mixin ExpansibleStateMixin<S extends StatefulWidget> on TickerProviderStateMixin<S> {
  ///
  bool get isExpanded => _isExpanded;
  bool _isExpanded = false;

  ///
  AnimationController get animationController => _animationController;
  late AnimationController _animationController;

  ///
  CurvedAnimation get heightFactor => _heightFactor;
  late CurvedAnimation _heightFactor;

  ///
  List<Widget> get children;

  ///
  ValueChanged<bool>? get onExpansionChanged;

  ///
  Duration get expansionDuration;

  ///
  Curve get expansionCurve;

  ///
  bool get initiallyExpanded;

  ///
  bool get maintainState;

  ///
  ExpansibleController<S> get controller;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: expansionDuration, vsync: this);
    _isExpanded = PageStorage.maybeOf(context)?.readState(context) as bool? ?? initiallyExpanded;
    if (_isExpanded) {
      _animationController.value = 1.0;
    }
    final Tween<double> heightFactorTween = Tween<double>(begin: 0.0, end: 1.0);
    _heightFactor = CurvedAnimation(
      parent: animationController.drive(heightFactorTween),
      curve: expansionCurve,
    );

    assert(controller._state == null);
    controller._state = this;
  }

  @override
  void dispose() {
    controller._state = null;
    _animationController.dispose();
    _heightFactor.dispose();
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

  @protected
  ///
  Widget buildExpansible(BuildContext context, Widget header, Widget body);

  @protected
  ///
  Widget buildHeader(BuildContext context);

  @protected
  ///
  Widget buildBody(BuildContext context);

  @override
  Widget build(BuildContext context) {
    final bool closed = !isExpanded && animationController.isDismissed;
    final bool shouldRemoveChildren = closed && !maintainState;

    final Widget result = Offstage(
      offstage: closed,
      child: TickerMode(enabled: !closed, child: buildBody(context)),
    );

    return AnimatedBuilder(
      animation: animationController.view,
      builder: (BuildContext context, Widget? child) {
        return buildExpansible(
          context,
          buildHeader(context),
          ClipRect(child: Align(heightFactor: heightFactor.value, child: child)),
        );
      },
      child: shouldRemoveChildren ? null : result,
    );
  }
}
