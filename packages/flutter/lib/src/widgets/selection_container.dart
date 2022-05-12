// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

import 'framework.dart';

/// A container that handles [SelectionEvent]s for the [Selectable]s in
/// the subtree.
///
/// This widget is useful when one wants to customize selection behaviors for
/// a group of [Selectable]s
///
/// The state of this container is a single selectable and will register
/// itself to the [registrar] if provided. Otherwise, it will register to the
/// [SelectionRegistrar] from the context.
///
/// The containers handle the [SelectionEvent]s from the registered
/// [SelectionRegistrar] and delegate the events to the [delegate].
///
/// This widget uses [SelectionRegistrarScope] to host the [delegate] as the
/// [SelectionRegistrar] for the subtree to collect the [Selectable]s, and
/// [SelectionEvent]s received by this container are sent to the [delegate] using
/// the [SelectionHandler] API of the delegate.
///
/// {@tool dartpad}
/// This sample demonstrates how to create a [SelectionContainer] that only
/// allows selecting everything or nothing with no partial selection.
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
  /// If [registrar] is not provided, this selection container gets the
  /// [SelectionRegistrar] from the context instead.
  ///
  /// The [delegate] must not be null.
  const SelectionContainer({
    super.key,
    this.registrar,
    required this.delegate,
    required this.child
  }) : assert(delegate != null);

  /// The [SelectionRegistrar] this container is registered to.
  ///
  /// If null, this widget gets the [SelectionRegistrar] from the current
  /// context.
  final SelectionRegistrar? registrar;

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
  final Set<VoidCallback> _listeners = <VoidCallback>{};
  @override
  void initState() {
    super.initState();
    widget.delegate._selectionContainerContext = context;
    if (widget.registrar != null)
      registrar = widget.registrar;
  }

  @override
  void didUpdateWidget(SelectionContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.delegate != widget.delegate) {
      oldWidget.delegate._selectionContainerContext = null;
      _listeners.forEach(oldWidget.delegate.removeListener);
      widget.delegate._selectionContainerContext = context;
      _listeners.forEach(widget.delegate.addListener);
      if (oldWidget.delegate.value != widget.delegate.value) {
        for (final VoidCallback listener in _listeners) {
          listener();
        }
      }
    }
    if (widget.registrar != null)
      registrar = widget.registrar;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.registrar == null) {
      registrar = SelectionRegistrarScope.maybeOf(context);
    }
  }

  @override
  void addListener(VoidCallback listener) {
    widget.delegate.addListener(listener);
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    widget.delegate.removeListener(listener);
    _listeners.remove(listener);
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
    widget.delegate._selectionContainerContext = null;
    _listeners.forEach(widget.delegate.removeListener);
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

/// A delegate to handle [SelectionEvent]s for a [SelectionContainer].
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
