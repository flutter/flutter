// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:ui' show FlutterView, SemanticsUpdate;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';
import 'lookup_boundary.dart';
import 'media_query.dart';

/// Bootstraps a render tree that is rendered into the provided [FlutterView].
///
/// The content rendered into that view is determined by the provided [child].
/// Descendants within the same [LookupBoundary] can look up the view they are
/// rendered into via [View.of] and [View.maybeOf].
///
/// The provided [child] is wrapped in a [MediaQuery] constructed from the given
/// [view].
///
/// Each [FlutterView] can be associated with at most one [View] widget in the
/// widget tree. Two or more [View] widgets configured with the same
/// [FlutterView] must never exist within the same widget tree at the same time.
/// Internally, this limitation is enforced by a [GlobalObjectKey] that derives
/// its identity from the [view] provided to this widget.
///
/// Since the [View] widget bootstraps its own independent render tree, neither
/// it not any of its descendants will insert a [RenderObject] into an existing
/// render tree. Therefore, the [View] widget can only be used in those parts of
/// the widget tree where it is not required to participate in the construction
/// of the surrounding render tree. In practical terms, this means it can
/// typically be used at the root of the widget tree outside of any other [View]
/// widget, as a child of a [ViewCollection] widget, or in the [ViewAnchor.view]
/// slot of a [ViewAnchor] widget. It might not be a direct child, though, since
/// other non-[RenderObjectWidget]s (e.g. [InheritedWidget]s) are allowed to be
/// present between those widgets and the [View] widget.
///
/// In technical terms, whether a [View] is allowed to occupy a certain slot of
/// an element is determined by that element's
/// [Element.debugMustInsertRenderObjectIntoSlot]
///
/// See also:
///
///  * [RawView], which is the workhorse behind this widget.
class View extends StatelessWidget {
  /// Create a [View] widget to bootstrap a render tree that is rendered into
  /// the provided [FlutterView].
  ///
  /// The content rendered into that [view] is determined by the given [child]
  /// widget.
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
       assert((deprecatedDoNotUseWillBeRemovedWithoutNoticePipelineOwner == null) == (deprecatedDoNotUseWillBeRemovedWithoutNoticeRenderView == null)),
       assert(deprecatedDoNotUseWillBeRemovedWithoutNoticeRenderView == null || deprecatedDoNotUseWillBeRemovedWithoutNoticeRenderView.flutterView == view);

  /// The [FlutterView] into which [child] is drawn.
  final FlutterView view;

  /// The widget below this widget in the tree, which will be drawn into the
  /// [view].
  ///
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
    return RawView._deprecated(
      view: view,
      deprecatedPipelineOwner: _deprecatedPipelineOwner,
      deprecatedRenderView: _deprecatedRenderView,
      builder: (BuildContext context, PipelineOwner owner) {
        return _ViewScope(
          view: view,
          child: ViewHooksScope(
            hooks: ViewHooks.of(context).copyWith(pipelineOwner: owner),
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

/// A builder for the content [Widget] of a [RawView].
///
/// The widget returned by the builder defines the content that is drawn into
/// the [FlutterView] configured on the [RawView].
///
/// The builder is given the [PipelineOwner] that the [RawView] uses to manage
/// its render tree. Typical builder implementations make that pipeline owner
/// available as an attachment point for potential child views by inserting
/// updated [ViewHooks] into the widget tree.
///
/// Used by [RawView.builder].
typedef RawViewContentBuilder = Widget Function(BuildContext context, PipelineOwner owner);

/// The workhorse behind the [View] widget that actually bootstraps a render
/// tree.
///
/// It instantiates the [RenderView] as the root of that render tree and adds it
/// to the [RenderViewManager] obtained from the surrounding [ViewHooks] via
/// [ViewHooks.of] (typically, that is the [RendererBinding]). It also owns the
/// [PipelineOwner] that manages this render tree and adds it as a child to the
/// surrounding [ViewHooks.pipelineOwner]. This ensures that the render tree
/// bootstrapped by this widget participates properly in frame production and
/// hit testing.
///
/// The [RawView] widget faces the same limitations in terms of where it can
/// appear in the widget tree as the [View] widget. See the [View] widget for
/// details.
///
/// The [RawView] widget is rarely used directly. Instead, consider using the
/// [View] widget, which also inserts a proper [MediaQuery] for the [view] into
/// the tree and provides updated [ViewHooks] to potential child views.
class RawView extends RenderObjectWidget {
  /// Create a [RawView] widget to bootstrap a render tree that is rendered into
  /// the provided [FlutterView].
  ///
  /// The content rendered into that [view] is determined by the [Widget]
  /// returned by [builder].
  RawView({
    required this.view,
    required this.builder,
  }) : _deprecatedPipelineOwner = null,
       _deprecatedRenderView = null,
       super(key: GlobalObjectKey(view));

  RawView._deprecated({
    required this.view,
    required PipelineOwner? deprecatedPipelineOwner,
    required RenderView? deprecatedRenderView,
    required this.builder,
  }) : _deprecatedPipelineOwner = deprecatedPipelineOwner,
       _deprecatedRenderView = deprecatedRenderView,
       assert(deprecatedRenderView == null || deprecatedRenderView.flutterView == view),
       super(key: _DeprecatedRawViewKey(view, deprecatedPipelineOwner, deprecatedRenderView));

  /// The [FlutterView] into which the [Widget] returned by [builder] is drawn.
  final FlutterView view;

  /// Determines the content [Widget] that is drawn into the [view].
  ///
  /// The [builder] is given the [PipelineOwner] responsible for the render tree
  /// bootstrapped by this widget. Typically, the [builder] inserts updated
  /// [ViewHooks] into the tree that contain this pipeline owner as an
  /// attachment point for potential child views.
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

  // No need to implement updateRenderObject: RawView uses the view as a
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
    try {
      final Widget child = (widget as RawView).builder(this, _effectivePipelineOwner);
      _child = updateChild(_child, child, null);
    } catch (e, stack) {
      final FlutterErrorDetails details = FlutterErrorDetails(
        exception: e,
        stack: stack,
        library: 'widgets library',
        context: ErrorDescription('building $this'),
        informationCollector: !kDebugMode ? null : () => <DiagnosticsNode>[
          DiagnosticsDebugCreator(DebugCreator(this)),
        ],
      );
      FlutterError.reportError(details);
      final Widget error = ErrorWidget.builder(details);
      _child = updateChild(null, error, slot);
    }
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    assert(_effectivePipelineOwner.rootNode == null);
    _effectivePipelineOwner.rootNode = renderObject;
    _attachToViewHooks();
    _updateChild();
    renderObject.prepareInitialFrame();
    if (_effectivePipelineOwner.semanticsOwner != null) {
      renderObject.scheduleInitialSemantics();
    }
  }

  ViewHooks? _attachmentPoint;

  void _attachToViewHooks([ViewHooks? viewHooks]) {
    assert(_attachmentPoint == null);
    viewHooks ??= ViewHooks.of(this);
    viewHooks.pipelineOwner.adoptChild(_effectivePipelineOwner);
    viewHooks.renderViewManager.addRenderView(renderObject);
    _attachmentPoint = viewHooks;
  }

  void _detachFromViewHooks() {
    final ViewHooks? viewHooks = _attachmentPoint;
    if (viewHooks != null) {
      viewHooks.renderViewManager.removeRenderView(renderObject);
      viewHooks.pipelineOwner.dropChild(_effectivePipelineOwner);
      _attachmentPoint = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_attachmentPoint == null) {
      return;
    }
    final ViewHooks newHooks = ViewHooks.of(this);
    if (newHooks != _attachmentPoint) {
      _detachFromViewHooks();
      _attachToViewHooks(newHooks);
    }
  }

  @override
  void performRebuild() {
    super.performRebuild();
    _updateChild();
  }

  @override
  void activate() {
    super.activate();
    assert(_effectivePipelineOwner.rootNode == null);
    _effectivePipelineOwner.rootNode = renderObject;
    _attachToViewHooks();
  }

  @override
  void deactivate() {
    _detachFromViewHooks();
    assert(_effectivePipelineOwner.rootNode == renderObject);
    _effectivePipelineOwner.rootNode = null; // To satisfy the assert in the super class.
    super.deactivate();
  }

  @override
  void update(RawView newWidget) {
    super.update(newWidget);
    _updateChild();
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

  @override
  void unmount() {
    if (_effectivePipelineOwner != (widget as RawView)._deprecatedPipelineOwner) {
      _effectivePipelineOwner.dispose();
    }
    super.unmount();
  }
}

class _ViewScope extends InheritedWidget {
  const _ViewScope({required this.view, required super.child});

  final FlutterView? view;

  @override
  bool updateShouldNotify(_ViewScope oldWidget) => view != oldWidget.view;
}

/// Injects [ViewHooks] into the widget tree so that they can be looked up by
/// descendants via [ViewHooks.of].
class ViewHooksScope extends InheritedWidget {
  /// Creates a [ViewHooksScope] that makes the provided [hooks] available to
  /// [child] and its descendants via [ViewHooks.of].
  const ViewHooksScope({
    super.key,
    required this.hooks,
    required super.child,
  });

  /// The [ViewHooks] made available to descendants via [ViewHooks.of].
  final ViewHooks hooks;

  @override
  bool updateShouldNotify(ViewHooksScope oldWidget) => hooks != oldWidget.hooks;
}

/// Attachment points for a [View] and the render tree that defines its content.
///
/// To participate in frame production, the [View] widget (or more specifically
/// the underlying [RawView] widget) needs to add the [RenderView] root of its
/// render tree to a [RenderViewManager] (typically, the [RendererBinding])
/// and add the [PipelineOwner] managing that tree to the pipeline owner tree.
/// The [ViewHooks] define these attachment points for the [View]/[RawView]
/// widget. They are injected into the tree via [ViewHooksScope] and can be
/// looked up with [ViewHooks.of].
@immutable
class ViewHooks {
  /// Creates a [ViewHooks] instance with the provided [renderViewManager]
  /// and [pipelineOwner].
  const ViewHooks({
    required this.renderViewManager,
    required this.pipelineOwner,
  });

  /// The [ViewHooks] of the closest [ViewHooksScope] instance that encloses the
  /// given `context`.
  ///
  /// Calling this method establishes a dependency and the provided `context`
  /// and causes it to rebuild whenever the [ViewHooks] change.
  ///
  /// When no [ViewHooks] are available in the provided `context`, a default
  /// ViewHooks instance with [renderViewManager] set to
  /// [RendererBinding.instance] and [pipelineOwner] set to
  /// [RendererBinding.rootPipelineOwner] is returned.
  static ViewHooks of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ViewHooksScope>()?.hooks
        ?? ViewHooks(
          renderViewManager: RendererBinding.instance,
          pipelineOwner: RendererBinding.instance.rootPipelineOwner,
        );
  }

  /// The [RenderViewManager] to which the [RawView] widget should add the
  /// [RenderView] root of its render tree by calling
  /// [RenderViewManager.addRenderView].
  final RenderViewManager renderViewManager;

  /// The parent [PipelineOwner] to which the [RawView] widget should add the
  /// [PipelineOwner] managing its render tree by calling
  /// [PipelineOwner.adoptChild].
  final PipelineOwner pipelineOwner;

  /// Create a clone of the current [ViewHooks] but with provided parameters
  /// replaced.
  ViewHooks copyWith({
    RenderViewManager? renderViewManager,
    PipelineOwner? pipelineOwner,
  }) {
    assert(renderViewManager != null || pipelineOwner != null);
    return ViewHooks(
      renderViewManager: renderViewManager ?? this.renderViewManager,
      pipelineOwner: pipelineOwner ?? this.pipelineOwner,
    );
  }

  @override
  int get hashCode => Object.hash(renderViewManager, pipelineOwner);

  @override
  bool operator ==(Object other) {
    return other is ViewHooks
        && renderViewManager == other.renderViewManager
        && pipelineOwner == other.pipelineOwner;
  }

  @override
  String toString() {
    return
      '${objectRuntimeType(this, 'ViewHooks')}('
        'pipelineOwner: $pipelineOwner, '
        'renderViewManager: $renderViewManager'
      ')';
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

/// A collection of sibling [View]s.
///
/// This widget can only be used in places were a [View] widget is allowed. In
/// practical terms, it can be used at the root of the widget tree outside of
/// any [View] widget, as a child to a another [ViewCollection], or in the
/// [ViewAnchor.view] slot of a [ViewAnchor] widget. It is not required to be a
/// direct child of those widgets; other non-[RenderObjectWidget]s may appear
/// in between the two (such as an [InheritedWidget]).
///
/// Similarly, the [views] children of this widget must be [View]s, but they
/// may be wrapped in additional non-[RenderObjectWidget]s (e.g.
/// [InheritedWidget]s).
class ViewCollection extends _MultiChildComponentWidget {
  /// Creates a [ViewCollection] widget.
  ///
  /// The provided list of [views] must contain at least one widget.
  const ViewCollection({super.key, required super.views}) : assert(views.length > 0);

  /// The [View] descendants of this widget.
  ///
  /// The [View]s may be wrapped in other non-[RenderObjectWidget]s (e.g.
  /// [InheritedWidget]s). However, no [RenderObjectWidget] is allowed to appear
  /// between the [ViewCollection] and the next [View] widget.
  List<Widget> get views => _views;
}

/// Decorates a [child] widget in a surrounding [View] with a side-[View].
///
/// This widget must have a [View] ancestor, into which the [child] widget
/// is rendered.
///
/// Typically, a [View] or [ViewCollection] widget is used in the [view] slot to
/// define the content of the side view(s). Those widgets may be wrapped in
/// other non-[RenderObjectWidget]s (e.g. [InheritedWidget]s). However, no
/// [RenderObjectWidget] is allowed to appear between the [ViewAnchor] and the
/// next [View] widget in the [view] slot. The widgets in the [view] slot have
/// access to all [InheritedWidget]s above the [ViewAnchor] in the tree.
///
/// {@template flutter.widgets.ViewAnchor}
/// An example use case for this widget is a tooltip for a button. The tooltip
/// should be able to extend beyond the bounds of the main view. For this, the
/// tooltip can be implemented as a separate [View], which is anchored to the
/// button in the main view by wrapping that button with a [ViewAnchor]. In this
/// example, the [view] slot is configured with the tooltip [View] and the
/// [child] is the button widget rendered into the surrounding view.
/// {@endtemplate}
class ViewAnchor extends StatelessWidget {
  /// Creates a [ViewAnchor] widget.
  const ViewAnchor({
    super.key,
    this.view,
    required this.child,
  });

  /// The widget that defines the view anchored to this widget.
  ///
  /// Typically, a [View] or [ViewCollection] widget is used, which may be
  /// wrapped in other non-[RenderObjectWidget]s (e.g. [InheritedWidget]s).
  ///
  /// {@macro flutter.widgets.ViewAnchor}
  final Widget? view;

  /// The widget below this widget in the tree.
  ///
  /// It is rendered into the surrounding view, not in the view defined by
  /// [view].
  ///
  /// {@macro flutter.widgets.ViewAnchor}
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
  void attachRenderObject(Object? newSlot) {
    super.attachRenderObject(newSlot);
    assert(_debugCheckMustAttachRenderObject(newSlot));
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    assert(_debugCheckMustAttachRenderObject(newSlot));
    assert(_viewElements.isEmpty);
    assert(_childElement == null);
    rebuild();
    assert(_debugAssertChildren());
  }

  @override
  void updateSlot(Object? newSlot) {
    super.updateSlot(newSlot);
    assert(_debugCheckMustAttachRenderObject(newSlot));
  }

  bool _debugCheckMustAttachRenderObject(Object? slot) {
    // Check only applies in the ViewCollection configuration.
    if (!kDebugMode || (widget as _MultiChildComponentWidget)._child != null) {
      return true;
    }
    bool hasAncestorRenderObjectElement = false;
    bool ancestorWantsRenderObject = true;
    visitAncestorElements((Element ancestor) {
      if (!ancestor.debugMustInsertRenderObjectIntoSlot(slot)) {
        ancestorWantsRenderObject = false;
        return false;
      }
      if (ancestor is RenderObjectElement) {
        hasAncestorRenderObjectElement = true;
        return false;
      }
      return true;
    });
    if (hasAncestorRenderObjectElement && ancestorWantsRenderObject) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: FlutterError.fromParts(
          <DiagnosticsNode>[
            ErrorSummary(
              'The Element for ${toStringShort()} cannot be inserted into slot "$slot" of its ancestor. ',
            ),
            ErrorDescription(
              'The ownership chain for the Element in question was:\n  ${debugGetCreatorChain(10)}',
            ),
            ErrorDescription(
              'This Element allows the creation of multiple independent render trees, which cannot '
              'be attached to an ancestor in an existing render tree. However, an ancestor RenderObject '
              'is expecting that a child will be attached.'
            ),
            ErrorHint(
              'Try moving the subtree that contains the ${toStringShort()} widget into the '
              'view property of a ViewAnchor widget or to the root of the widget tree, where '
              'it is not expected to attach its RenderObject to its ancestor.',
            ),
          ],
        )),
      );
    }
    return true;
  }

  @override
  void update(_MultiChildComponentWidget newWidget) {
    // Cannot switch from ViewAnchor config to ViewCollection config.
    assert((newWidget._child == null) == ((widget as _MultiChildComponentWidget)._child == null));
    super.update(newWidget);
    rebuild(force: true);
    assert(_debugAssertChildren());
  }

  static const Object _viewSlot = Object();

  @override
  bool debugMustInsertRenderObjectIntoSlot(Object? slot) => slot != _viewSlot;

  @override
  void performRebuild() {
    final _MultiChildComponentWidget typedWidget = widget as _MultiChildComponentWidget;

    _childElement = updateChild(_childElement, typedWidget._child, slot);

    final List<Widget> views = typedWidget._views;
    _viewElements = updateChildren(
      _viewElements,
      views,
      forgottenChildren: _forgottenViewElements,
      slots: List<Object>.generate(views.length, (_) => _viewSlot),
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
  Element? get renderObjectAttachingChild => _childElement;

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

// A special [GlobalKey] to support passing the deprecated
// [RendererBinding.renderView] and [RendererBinding.pipelineOwner] to the
// [RawView]. Will be removed when those deprecated properties are removed.
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
