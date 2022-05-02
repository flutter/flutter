// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';

/// A container that handles selection events for the [Selectable]s in
/// the subtree.
///
/// This widget is useful when one wants to customize selection behaviors for
/// a group of [Selectable]s
///
/// The render object of this container is a single selectable and will register
/// itself to the [registrar]. The containers handle the [SelectionEvent]s from
/// the [registrar] and delegate the events to the [delegate].
///
/// This widget uses [SelectionRegistrarScope] to host the [delegate] as the
/// [SelectionRegistrar] for the subtree to collect the [Selectable]s, and
/// [SelectionEvent]s received by this container are sent to the [delegate] using
/// the [SelectionHandler] API of the delegate.
///
/// To use this widget, set the [registrar] this container received the
/// [SelectionEvent]s from. Use [SelectionRegistrarScope.maybeOf] to retrieve
/// the registrar that is relevant to the current context, and then create a
/// subclass of [SelectionContainerDelegate] to decide how the selections are
/// handled.
///
/// {@tool dartpad}
/// This sample demonstrates how to create a select-all-or-none container
///
/// ** See code in examples/api/lib/material/selection_area/custom_container.dart **
/// {@end-tool}
///
/// See also:
///  * [SelectableRegion], which provides an overview of the selection system.
///  * [SelectionRegistrarScope.disabled], which disable selection for a
///    subtree.
class SelectionContainer extends StatefulWidget {
  /// Creates a selection container to collect the [Selectable]s in the subtree.
  ///
  /// The [registrar] and [delegate] must not be null.
  const SelectionContainer({
    super.key,
    required this.registrar,
    required this.delegate,
    required this.child
  }) : assert(registrar != null && delegate != null);

  /// The [SelectionRegistrar] this container is registered to.
  final SelectionRegistrar registrar;

  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  /// The delegate for [SelectionEvent]s sent to this selection container.
  ///
  /// The [Selectable]s in the subtree is added or removed from this delegate
  /// uses [SelectionRegistrar] API.
  ///
  /// This delegate is responsible for updating the selections for the selectables
  /// under this widget.
  final SelectionContainerDelegate delegate;

  @override
  State<SelectionContainer> createState() => _SelectionContainerState();
}

class _SelectionContainerState extends State<SelectionContainer> with Selectable, SelectionRegistrant {
  final Set<Selectable> _registeredSelectables = <Selectable>{};
  late final ValueNotifier<SelectionGeometry> _notifier;

  @override
  void initState() {
    super.initState();
    widget.delegate._selectionContainerContext = context;
    widget.delegate.addListener(_onSelectionGeometryChange);
    _notifier = ValueNotifier<SelectionGeometry>(widget.delegate.value);
    registrar = widget.registrar;
  }

  void _onSelectionGeometryChange() {
    _notifier.value = widget.delegate.value;
  }

  @override
  void didUpdateWidget(SelectionContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.delegate != widget.delegate) {
      oldWidget.delegate._selectionContainerContext = null;
      oldWidget.delegate.removeListener(_onSelectionGeometryChange);
      widget.delegate._selectionContainerContext = context;
      widget.delegate.addListener(_onSelectionGeometryChange);
      _notifier.value = widget.delegate.value;
    }
    registrar = widget.registrar;
  }

  @override
  void addListener(VoidCallback listener) {
    _notifier.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _notifier.removeListener(listener);
  }

  @override
  void pushHandleLayers(LayerLink? startHandle, LayerLink? endHandle) {
    widget.delegate.pushHandleLayers(startHandle, endHandle);
  }

  @override
  SelectedContent? getSelectedContent() => widget.delegate.getSelectedContent();

  @override
  SelectionResult dispatchSelectionEvent(SelectionEvent event) {
    return widget.delegate.dispatchSelectionEvent(event);
  }

  @override
  SelectionGeometry get value => widget.delegate.value;

  @override
  Matrix4 getTransformTo(RenderObject? ancestor) {
    return context.findRenderObject()!.getTransformTo(ancestor);
  }

  @override
  Size get size => (context.findRenderObject()! as RenderBox).size;

  @override
  void dispose() {
    _registeredSelectables.clear();
    widget.delegate.removeListener(_onSelectionGeometryChange);
    widget.delegate._selectionContainerContext = null;
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SelectionRegistrarScope(
      registrar: widget.delegate,
      child: widget.child,
    );
  }
}

/// An inherited widget to host a [SelectionRegistrar] for the subtree.
///
/// Use [SelectionRegistrarScope.maybeOf] to get the SelectionRegistrar from
/// a context.
///
/// This widget is automatically created as part of [SelectionContainer] and
/// is generally not used directly, except for disabling selection for a part
/// of subtree. In that case, one can wrap the subtree with
/// [SelectionRegistrarScope.disabled].
class SelectionRegistrarScope extends InheritedWidget {
  /// Creates a selection registrar scope that host the [registrar].
  const SelectionRegistrarScope({
    super.key,
    required SelectionRegistrar this.registrar,
    required super.child,
  }) : assert(registrar != null);

  /// Creates a selection registrar scope that disables selection for the
  /// subtree.
  const SelectionRegistrarScope.disabled({
    super.key,
    required super.child,
  }) : registrar = null;

  /// Gets the immediate ancestor [SelectionRegistrar] of the [BuildContext].
  ///
  /// If this returns null, either there is no [SelectionRegistrarScope] above
  /// the [BuildContext] or the immediate [SelectionRegistrarScope] is not
  /// enabled.
  static SelectionRegistrar? maybeOf(BuildContext context) {
    final SelectionRegistrarScope? scope = context.dependOnInheritedWidgetOfExactType<SelectionRegistrarScope>();
    return scope?.registrar;
  }

  /// The [SelectionRegistrar] hosted by this widget.
  final SelectionRegistrar? registrar;

  @override
  bool updateShouldNotify(SelectionRegistrarScope oldWidget) {
    return oldWidget.registrar != registrar;
  }
}

/// A delegate to handle selection events for a [SelectionContainer].
///
/// This delegate needs to implement [SelectionRegistrar] to register
/// [Selectable]s in the [SelectionContainer] subtree.
abstract class SelectionContainerDelegate implements SelectionHandler, SelectionRegistrar {
  /// The context of the selection container that holds this delegate.
  ///
  /// This is useful when retrieving layout geometry of the container.
  @protected
  BuildContext get selectionContainerContext => _selectionContainerContext!;
  BuildContext? _selectionContainerContext;
}
