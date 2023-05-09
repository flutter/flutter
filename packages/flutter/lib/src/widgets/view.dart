// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:collection';
import 'dart:ui' show FlutterView, SemanticsUpdate;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';
import 'lookup_boundary.dart';
import 'media_query.dart';

/// Injects a [FlutterView] into the tree and makes it available to descendants
/// within the same [LookupBoundary] via [View.of] and [View.maybeOf].
///
/// The provided [child] is wrapped in a [MediaQuery] constructed from the given
/// [view].
///
/// In a future version of Flutter, the functionality of this widget will be
/// extended to actually bootstrap the render tree that is going to be rendered
/// into the provided [view]. This will enable rendering content into multiple
/// [FlutterView]s from a single widget tree.
///
/// Each [FlutterView] can be associated with at most one [View] widget in the
/// widget tree. Two or more [View] widgets configured with the same
/// [FlutterView] must never exist within the same widget tree at the same time.
/// Internally, this limitation is enforced by a [GlobalObjectKey] that derives
/// its identity from the [view] provided to this widget.
class View extends StatelessWidget {
  /// Injects the provided [view] into the widget tree.
  View({
    super.key,
    required this.view,
    @Deprecated(
      'Do not use. '
      'This parameter only exists to implement the deprecated RendererBinding.pipelineOwner property until it is removed. '
      'This feature was deprecated after v3.10.0-12.0.pre.'
    )
    PipelineOwner? deprecatedDoNotUseWillBeRemovedWithoutNoticePipelineOwner,
    @Deprecated(
      'Do not use. '
      'This parameter only exists to implement the deprecated RendererBinding.renderView property until it is removed. '
      'This feature was deprecated after v3.10.0-12.0.pre.'
    )
    RenderView? deprecatedDoNotUseWillBeRemovedWithoutNoticeRenderView,
    required this.child,
  }) : _deprecatedPipelineOwner = deprecatedDoNotUseWillBeRemovedWithoutNoticePipelineOwner,
       _deprecatedRenderView = deprecatedDoNotUseWillBeRemovedWithoutNoticeRenderView,
       assert(deprecatedDoNotUseWillBeRemovedWithoutNoticeRenderView == null || deprecatedDoNotUseWillBeRemovedWithoutNoticeRenderView.flutterView == view);

  /// The [FlutterView] to be injected into the tree.
  final FlutterView view;

  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  final PipelineOwner? _deprecatedPipelineOwner;
  final RenderView? _deprecatedRenderView;

  /// Returns the [FlutterView] that the provided `context` will render into.
  ///
  /// Returns null if the `context` is not associated with a [FlutterView].
  ///
  /// The method creates a dependency on the `context`, which will be informed
  /// when the identity of the [FlutterView] changes (i.e. the `context` is
  /// moved to render into a different [FlutterView] then before). The context
  /// will not be informed when the properties on the [FlutterView] itself
  /// change their values. To access the property values of a [FlutterView] it
  /// is best practise to use [MediaQuery.maybeOf] instead, which will ensure
  /// that the `context` is informed when the view properties change.
  ///
  /// See also:
  ///
  ///  * [View.of], which throws instead of returning null if no [FlutterView]
  ///    is found.
  static FlutterView? maybeOf(BuildContext context) {
    return LookupBoundary.dependOnInheritedWidgetOfExactType<_ViewScope>(context)?.view;
  }

  /// Returns the [FlutterView] that the provided `context` will render into.
  ///
  /// Throws if the `context` is not associated with a [FlutterView].
  ///
  /// The method creates a dependency on the `context`, which will be informed
  /// when the identity of the [FlutterView] changes (i.e. the `context` is
  /// moved to render into a different [FlutterView] then before). The context
  /// will not be informed when the properties on the [FlutterView] itself
  /// change their values. To access the property values of a [FlutterView] it
  /// is best practise to use [MediaQuery.of] instead, which will ensure that
  /// the `context` is informed when the view properties change.
  ///
  /// See also:
  ///
  ///  * [View.maybeOf], which throws instead of returning null if no
  ///    [FlutterView] is found.
  static FlutterView of(BuildContext context) {
    final FlutterView? result = maybeOf(context);
    assert(() {
      if (result == null) {
        final bool hiddenByBoundary = LookupBoundary.debugIsHidingAncestorWidgetOfExactType<_ViewScope>(context);
        final List<DiagnosticsNode> information = <DiagnosticsNode>[
          if (hiddenByBoundary) ...<DiagnosticsNode>[
            ErrorSummary('View.of() was called with a context that does not have access to a View widget.'),
            ErrorDescription('The context provided to View.of() does have a View widget ancestor, but it is hidden by a LookupBoundary.'),
          ] else ...<DiagnosticsNode>[
            ErrorSummary('View.of() was called with a context that does not contain a View widget.'),
            ErrorDescription('No View widget ancestor could be found starting from the context that was passed to View.of().'),
          ],
          ErrorDescription(
            'The context used was:\n'
            '  $context',
          ),
          ErrorHint('This usually means that the provided context is not associated with a View.'),
        ];
        throw FlutterError.fromParts(information);
      }
      return true;
    }());
    return result!;
  }

  @override
  Widget build(BuildContext context) {
    final ViewHooks ancestorHock = ViewHooks.of(context);
    return RawView._deprecated(
      view: view,
      hooks: ancestorHock,
      deprecatedPipelineOwner: _deprecatedPipelineOwner,
      deprecatedRenderView: _deprecatedRenderView,
      builder: (BuildContext context, PipelineOwner owner) {
        return _ViewScope(
          view: view,
          child: ViewHooksScope(
            hooks: ancestorHock.copyWith(pipelineOwner: owner),
            child: MediaQuery.fromView(
              view: view,
              child: child,
            ),
          ),
        );
      }
    );
  }
}

typedef RawViewContentBuilder = Widget Function(BuildContext context, PipelineOwner owner);

class RawView extends RenderObjectWidget {
  RawView({
    required this.view,
    required this.hooks,
    required this.builder,
  }) : _deprecatedPipelineOwner = null,
       _deprecatedRenderView = null,
       super(key: GlobalObjectKey(view));

  RawView._deprecated({
    required this.view,
    required this.hooks,
    PipelineOwner? deprecatedPipelineOwner,
    RenderView? deprecatedRenderView,
    required this.builder,
  }) : _deprecatedPipelineOwner = deprecatedPipelineOwner,
       _deprecatedRenderView = deprecatedRenderView,
       assert(deprecatedRenderView == null || deprecatedRenderView.flutterView == view),
       super(key: _DeprecatedRawViewKey(view, deprecatedPipelineOwner, deprecatedRenderView));

  final FlutterView view;
  final ViewHooks hooks;
  final RawViewContentBuilder builder;

  final PipelineOwner? _deprecatedPipelineOwner;
  final RenderView? _deprecatedRenderView;

  @override
  RenderObjectElement createElement() => _RawViewElement(this);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _deprecatedRenderView ?? RenderView(
      view: view,
    );
  }

  // No need to implement updateRenderObject: The View widget uses the view as a
  // GlobalKey, so we never need to update the RenderObject with a new view.
}

class _RawViewElement extends RenderTreeRootElement {
  _RawViewElement(super.widget);

  late final PipelineOwner _pipelineOwner = PipelineOwner(
    onSemanticsOwnerCreated: _handleSemanticsOwnerCreated,
    onSemanticsUpdate: _handleSemanticsUpdate,
    onSemanticsOwnerDisposed: _handleSemanticsOwnerDisposed,
  );

  PipelineOwner get _effectivePipelineOwner => (widget as RawView)._deprecatedPipelineOwner ?? _pipelineOwner;

  void _handleSemanticsOwnerCreated() {
    (_effectivePipelineOwner.rootNode as RenderView?)?.scheduleInitialSemantics();
    // If the rootNode is not set yet, initial semantics are scheduled in _ViewElement.mount right after the rootNode is set.
  }

  void _handleSemanticsOwnerDisposed() {
    (_effectivePipelineOwner.rootNode as RenderView?)?.clearSemantics();
  }

  void _handleSemanticsUpdate(SemanticsUpdate update) {
    (widget as RawView).view.updateSemantics(update);
  }

  @override
  RenderView get renderObject => super.renderObject as RenderView;

  Element? _child;

  void _updateChild() {
    // TODO(goderbauer): Error catching around builder.
    final Widget child = (widget as RawView).builder(this, _effectivePipelineOwner);
    _child = updateChild(_child, child, null);
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    // TODO(goderbauer): why do we need this? - Views are only allowed in certain places.
    // assert(newSlot == View.viewSlot);
    super.mount(parent, newSlot); // calls attachRenderObject(), updates slot member.
    _updateChild();
    renderObject.prepareInitialFrame();
    if (_effectivePipelineOwner.semanticsOwner != null) {
      renderObject.scheduleInitialSemantics();
    }
  }

  bool _attached = false;

  @override
  void attachRenderObject(Object? newSlot) {
    // assert(newSlot == View.viewSlot);
    final RawView viewWidget = widget as RawView;
    viewWidget.hooks.pipelineOwner.adoptChild(_effectivePipelineOwner);
    assert(_effectivePipelineOwner.rootNode == null);
    _effectivePipelineOwner.rootNode = renderObject;
    viewWidget.hooks.renderViewRepository.addRenderView(renderObject);
    _attached = true;
    super.attachRenderObject(newSlot); // updates slot member
  }

  @override
  void detachRenderObject() {
    final RawView viewWidget = widget as RawView;
    if (!_attached) {
      // In global key move scenarios `detachRenderObject` is called twice.
      assert(_effectivePipelineOwner.rootNode == null);
      return;
    }
    viewWidget.hooks.renderViewRepository.removeRenderView(renderObject);
    assert(_effectivePipelineOwner.rootNode == renderObject);
    _effectivePipelineOwner.rootNode = null;
    viewWidget.hooks.pipelineOwner.dropChild(_effectivePipelineOwner);
    _attached = false;
    super.detachRenderObject(); // updates slot member
  }

  @override
  void update(RawView oldWidget) {
    super.update(oldWidget);
    _updateChild();
    final RawView viewWidget = widget as RawView;
    final ViewHooks oldHooks = oldWidget.hooks;
    final ViewHooks newHooks = viewWidget.hooks;
    if (oldHooks.pipelineOwner != newHooks.pipelineOwner) {
      oldHooks.pipelineOwner.dropChild(_effectivePipelineOwner);
      newHooks.pipelineOwner.adoptChild(_effectivePipelineOwner);
    }
    if (oldHooks.renderViewRepository != newHooks.renderViewRepository) {
      oldHooks.renderViewRepository.removeRenderView(renderObject);
      newHooks.renderViewRepository.addRenderView(renderObject);
    }
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_child != null) {
      visitor(_child!);
    }
  }

  @override
  void forgetChild(Element child) {
    assert(child == _child);
    _child = null;
    super.forgetChild(child);
  }

  @override
  void insertRenderObjectChild(RenderBox child, Object? slot) {
    assert(slot == null);
    assert(renderObject.debugValidateChild(child));
    renderObject.child = child;
  }

  @override
  void moveRenderObjectChild(RenderObject child, Object? oldSlot, Object? newSlot) {
    assert(false);
  }

  @override
  void removeRenderObjectChild(RenderObject child, Object? slot) {
    assert(slot == null);
    assert(renderObject.child == child);
    renderObject.child = null;
  }
}

class _ViewScope extends InheritedWidget {
  const _ViewScope({required this.view, required super.child});

  final FlutterView? view;

  @override
  bool updateShouldNotify(_ViewScope oldWidget) => view != oldWidget.view;
}

class ViewHooksScope extends InheritedWidget {
  const ViewHooksScope({
    super.key,
    required this.hooks,
    required super.child,
  });

  final ViewHooks hooks;

  @override
  bool updateShouldNotify(ViewHooksScope oldWidget) => hooks != oldWidget.hooks;
}

@immutable
class ViewHooks {
  const ViewHooks({
    required this.renderViewRepository,
    required this.pipelineOwner,
  });

  static ViewHooks of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ViewHooksScope>()!.hooks;
  }

  final RenderViewRepository renderViewRepository;
  final PipelineOwner pipelineOwner;

  ViewHooks copyWith({
    RenderViewRepository? renderViewRepository,
    PipelineOwner? pipelineOwner,
  }) {
    assert(renderViewRepository != null || pipelineOwner != null);
    return ViewHooks(
      renderViewRepository: renderViewRepository ?? this.renderViewRepository,
      pipelineOwner: pipelineOwner ?? this.pipelineOwner,
    );
  }

  @override
  int get hashCode => Object.hash(renderViewRepository, pipelineOwner);

  @override
  bool operator ==(Object other) {
    return other is ViewHooks
        && renderViewRepository == other.renderViewRepository
        && pipelineOwner == other.pipelineOwner;
  }
}

class _MultiChildComponentWidget extends Widget {
  const _MultiChildComponentWidget({
    super.key,
    List<Widget> views = const <Widget>[],
    Widget? child,
  }) : _views = views, _child = child;

  // It is up to the subclasses to make the relevant properties public.
  final List<Widget> _views;
  final Widget? _child;

  @override
  Element createElement() => _MultiChildComponentElement(this);
}

class ViewCollection extends _MultiChildComponentWidget {
  const ViewCollection({super.key, required super.views}) : assert(views.length > 0);

  List<Widget> get view => _views;
}

class ViewAnchor extends StatelessWidget {
  const ViewAnchor({
    super.key,
    this.view,
    required this.child,
  });

  final Widget? view;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _MultiChildComponentWidget(
      views: <Widget>[
        if (view != null)
          _ViewScope(
            view: null,
            child: view!,
          ),
      ],
      child: child,
    );
  }
}

class _MultiChildComponentElement extends Element {
  _MultiChildComponentElement(super.widget);

  List<Element> _viewElements = <Element>[];
  final Set<Element> _forgottenViewElements = HashSet<Element>();
  Element? _childElement;

  bool _debugAssertChildren() {
    final _MultiChildComponentWidget typedWidget = widget as _MultiChildComponentWidget;
    // Each view widget must have a corresponding element.
    assert(_viewElements.length == typedWidget._views.length);
    // Iff there is a child widget, it must have a corresponding element.
    assert((_childElement == null) == (typedWidget._child == null));
    // The child element is not also a view element.
    assert(!_viewElements.contains(_childElement));
    return true;
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    assert(_viewElements.isEmpty);
    assert(_childElement == null);
    rebuild();
    assert(_debugAssertChildren());
  }

  @override
  void update(Widget newWidget) {
    super.update(newWidget);
    rebuild(force: true);
    assert(_debugAssertChildren());
  }

  @override
  void performRebuild() {
    final _MultiChildComponentWidget typedWidget = widget as _MultiChildComponentWidget;

    _childElement = updateChild(_childElement, typedWidget._child, slot);

    final List<Widget> views = typedWidget._views;
    _viewElements = updateChildren(
      _viewElements,
      views,
      forgottenChildren: _forgottenViewElements,
      // TODO(goderbauer): figure out slots
      // slots: List<Object>.generate(stages.length, (_) => View.viewSlot),
    );
    _forgottenViewElements.clear();

    super.performRebuild(); // clears the dirty flag
    assert(_debugAssertChildren());
  }

  @override
  void forgetChild(Element child) {
    if (child == _childElement) {
      _childElement = null;
    } else {
      assert(_viewElements.contains(child));
      assert(!_forgottenViewElements.contains(child));
      _forgottenViewElements.add(child);
    }
    super.forgetChild(child);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_childElement != null) {
      visitor(_childElement!);
    }
    for (final Element child in _viewElements) {
      if (!_forgottenViewElements.contains(child)) {
        visitor(child);
      }
    }
  }

  @override
  bool get debugDoingBuild => false; // This element does not have a concept of "building".

  @override
  // TODO(window): Update documentation.
  // TODO(goderbauer): The base class implementation doesn't consider this currently.
  RenderObject? get renderObject {
    // If we don't have a _childElement this returns null on purpose because
    // nothing above this element has an associated render object.
    return _childElement?.renderObject;
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> children = <DiagnosticsNode>[];
    if (_childElement != null) {
      children.add(_childElement!.toDiagnosticsNode());
    }
    for (int i = 0; i < _viewElements.length; i++) {
      children.add(_viewElements[i].toDiagnosticsNode(
        name: 'view ${i + 1}',
        style: DiagnosticsTreeStyle.offstage,
      ));
    }
    return children;
  }
}

@optionalTypeArgs
class _DeprecatedRawViewKey<T extends State<StatefulWidget>> extends GlobalKey<T> {
  const _DeprecatedRawViewKey(this.view, this.owner, this.renderView) : super.constructor();

  final FlutterView view;
  final PipelineOwner? owner;
  final RenderView? renderView;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is _DeprecatedRawViewKey<T>
        && identical(other.view, view)
        && identical(other.owner, owner)
        && identical(other.renderView, renderView);
  }

  @override
  int get hashCode => Object.hash(view, owner, renderView);

  @override
  String toString() => '[_DeprecatedRawViewKey ${describeIdentity(view)}]';
}
