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
///  * [SelectionContainer.disabled], which disable selection for a
///    subtree.
class SelectionContainer extends StatefulWidget {
  /// Creates a selection container to collect the [Selectable]s in the subtree.
  ///
  /// If [registrar] is not provided, this selection container gets the
  /// [SelectionRegistrar] from the context instead.
  ///
  /// The [delegate] and [child] must not be null.
  const SelectionContainer({
    super.key,
    this.registrar,
    required SelectionContainerDelegate this.delegate,
    required this.child,
  }) : assert(delegate != null),
       assert(child != null);

  /// Creates a selection container that disables selection for the
  /// subtree.
  ///
  /// The [child] must not be null.
  const SelectionContainer.disabled({
    super.key,
    required this.child,
  }) : registrar = null,
       delegate = null;

  /// The [SelectionRegistrar] this container is registered to.
  ///
  /// If null, this widget gets the [SelectionRegistrar] from the current
  /// context.
  final SelectionRegistrar? registrar;

  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  /// The delegate for [SelectionEvent]s sent to this selection container.
  ///
  /// The [Selectable]s in the subtree are added or removed from this delegate
  /// using [SelectionRegistrar] API.
  ///
  /// This delegate is responsible for updating the selections for the selectables
  /// under this widget.
  final SelectionContainerDelegate? delegate;

  /// Gets the immediate ancestor [SelectionRegistrar] of the [BuildContext].
  ///
  /// If this returns null, either there is no [SelectionContainer] above
  /// the [BuildContext] or the immediate [SelectionContainer] is not
  /// enabled.
  static SelectionRegistrar? maybeOf(BuildContext context) {
    final SelectionRegistrarScope? scope = context.dependOnInheritedWidgetOfExactType<SelectionRegistrarScope>();
    return scope?.registrar;
  }

  bool get _disabled => delegate == null;

  @override
  State<SelectionContainer> createState() => _SelectionContainerState();
}

class _SelectionContainerState extends State<SelectionContainer> with Selectable, SelectionRegistrant {
  final Set<VoidCallback> _listeners = <VoidCallback>{};

  static const SelectionGeometry _disabledGeometry = SelectionGeometry(
    status: SelectionStatus.none,
    hasContent: true,
  );

  @override
  void initState() {
    super.initState();
    if (!widget._disabled) {
      widget.delegate!._selectionContainerContext = context;
      if (widget.registrar != null) {
        registrar = widget.registrar;
      }
    }
  }

  @override
  void didUpdateWidget(SelectionContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.delegate != widget.delegate) {
      if (!oldWidget._disabled) {
        oldWidget.delegate!._selectionContainerContext = null;
        _listeners.forEach(oldWidget.delegate!.removeListener);
      }
      if (!widget._disabled) {
        widget.delegate!._selectionContainerContext = context;
        _listeners.forEach(widget.delegate!.addListener);
      }
      if (oldWidget.delegate?.value != widget.delegate?.value) {
        for (final VoidCallback listener in _listeners) {
          listener();
        }
      }
    }
    if (widget._disabled) {
      registrar = null;
    } else if (widget.registrar != null) {
      registrar = widget.registrar;
    }
    assert(!widget._disabled || registrar == null);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.registrar == null && !widget._disabled) {
      registrar = SelectionContainer.maybeOf(context);
    }
    assert(!widget._disabled || registrar == null);
  }

  @override
  void addListener(VoidCallback listener) {
    assert(!widget._disabled);
    widget.delegate!.addListener(listener);
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    widget.delegate?.removeListener(listener);
    _listeners.remove(listener);
  }

  @override
  void pushHandleLayers(LayerLink? startHandle, LayerLink? endHandle) {
    assert(!widget._disabled);
    widget.delegate!.pushHandleLayers(startHandle, endHandle);
  }

  @override
  SelectedContent? getSelectedContent() {
    assert(!widget._disabled);
    return widget.delegate!.getSelectedContent();
  }

  @override
  SelectionResult dispatchSelectionEvent(SelectionEvent event) {
    assert(!widget._disabled);
    return widget.delegate!.dispatchSelectionEvent(event);
  }

  @override
  SelectionGeometry get value {
    if (widget._disabled) {
      return _disabledGeometry;
    }
    return widget.delegate!.value;
  }

  @override
  Matrix4 getTransformTo(RenderObject? ancestor) {
    assert(!widget._disabled);
    return context.findRenderObject()!.getTransformTo(ancestor);
  }

  @override
  Size get size => (context.findRenderObject()! as RenderBox).size;

  @override
  void dispose() {
    if (!widget._disabled) {
      widget.delegate!._selectionContainerContext = null;
      _listeners.forEach(widget.delegate!.removeListener);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget._disabled) {
      return SelectionRegistrarScope._disabled(child: widget.child);
    }
    return SelectionRegistrarScope(
      registrar: widget.delegate!,
      child: widget.child,
    );
  }
}

/// An inherited widget to host a [SelectionRegistrar] for the subtree.
///
/// Use [SelectionContainer.maybeOf] to get the SelectionRegistrar from
/// a context.
///
/// This widget is automatically created as part of [SelectionContainer] and
/// is generally not used directly, except for disabling selection for a part
/// of subtree. In that case, one can wrap the subtree with
/// [SelectionContainer.disabled].
class SelectionRegistrarScope extends InheritedWidget {
  /// Creates a selection registrar scope that host the [registrar].
  const SelectionRegistrarScope({
    super.key,
    required SelectionRegistrar this.registrar,
    required super.child,
  }) : assert(registrar != null);

  /// Creates a selection registrar scope that disables selection for the
  /// subtree.
  const SelectionRegistrarScope._disabled({
    required super.child,
  }) : registrar = null;

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
  BuildContext? _selectionContainerContext;

  /// Gets the paint transform from the [Selectable] child to
  /// [SelectionContainer] of this delegate.
  ///
  /// Returns a matrix that maps the [Selectable] paint coordinate system to the
  /// coordinate system of [SelectionContainer].
  ///
  /// Can only be called after [SelectionContainer] is laid out.
  Matrix4 getTransformFrom(Selectable child) {
    assert(
      _selectionContainerContext?.findRenderObject() != null,
      'getTransformFrom cannot be called before SelectionContainer is laid out.',
    );
    return child.getTransformTo(_selectionContainerContext!.findRenderObject()! as RenderBox);
  }

  /// Gets the paint transform from the [SelectionContainer] of this delegate to
  /// the `ancestor`.
  ///
  /// Returns a matrix that maps the [SelectionContainer] paint coordinate
  /// system to the coordinate system of `ancestor`.
  ///
  /// If `ancestor` is null, this method returns a matrix that maps from the
  /// local paint coordinate system to the coordinate system of the
  /// [PipelineOwner.rootNode].
  ///
  /// Can only be called after [SelectionContainer] is laid out.
  Matrix4 getTransformTo(RenderObject? ancestor) {
    assert(
      _selectionContainerContext?.findRenderObject() != null,
      'getTransformTo cannot be called before SelectionContainer is laid out.',
    );
    final RenderBox box = _selectionContainerContext!.findRenderObject()! as RenderBox;
    return box.getTransformTo(ancestor);
  }

  /// Gets the size of the [SelectionContainer] of this delegate.
  ///
  /// Can only be called after [SelectionContainer] is laid out.
  Size get containerSize {
    assert(
      _selectionContainerContext?.findRenderObject() != null,
      'containerSize cannot be called before SelectionContainer is laid out.',
    );
    final RenderBox box = _selectionContainerContext!.findRenderObject()! as RenderBox;
    return box.size;
  }
}
