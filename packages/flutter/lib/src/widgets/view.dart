// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:ui' show FlutterView, SemanticsUpdate;

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
class View extends StatefulWidget {
  /// Injects the provided [view] into the widget tree.
  View({
    required this.view,
    @Deprecated('Do not use')
    PipelineOwner? deprecatedDoNotUseWillBeRemovedWithoutNoticePipelineOwner,
    @Deprecated('Do not use')
    RenderView? deprecatedDoNotUseWillBeRemovedWithoutNoticeRenderView,
    required this.child,
  }) : _deprecatedPipelineOwner = deprecatedDoNotUseWillBeRemovedWithoutNoticePipelineOwner,
       _deprecatedRenderView = deprecatedDoNotUseWillBeRemovedWithoutNoticeRenderView,
       assert(deprecatedDoNotUseWillBeRemovedWithoutNoticeRenderView == null || deprecatedDoNotUseWillBeRemovedWithoutNoticeRenderView.flutterView == view),
       super(key: GlobalObjectKey(view));

  /// The [FlutterView] to be injected into the tree.
  final FlutterView view;

  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  final PipelineOwner? _deprecatedPipelineOwner;
  final RenderView? _deprecatedRenderView;

  @override
  State<View> createState() => _ViewState();

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
}

class _ViewState extends State<View> {
  // Pulled out of _ViewRenderObjectWidgetElement to configure ViewHooksScope.
  late final PipelineOwner _pipelineOwner = PipelineOwner(
    onSemanticsOwnerCreated: _handleSemanticsOwnerCreated,
    onSemanticsUpdate: _handleSemanticsUpdate,
    onSemanticsOwnerDisposed: _handleSemanticsOwnerDisposed,
  );

  void _handleSemanticsOwnerCreated() {
    (_pipelineOwner.rootNode as RenderView?)?.scheduleInitialSemantics();
    // If the rootNode is not set yet, initial semantics are scheduled in _ViewElement.mount right after the rootNode is set.
  }

  void _handleSemanticsOwnerDisposed() {
    (_pipelineOwner.rootNode as RenderView?)?.clearSemantics();
  }

  void _handleSemanticsUpdate(SemanticsUpdate update) {
    widget.view.updateSemantics(update);
  }

  PipelineOwner get _effectivePipelineOwner => widget._deprecatedPipelineOwner ?? _pipelineOwner;

  @override
  void didUpdateWidget(View oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(oldWidget._deprecatedPipelineOwner == widget._deprecatedPipelineOwner);
    assert(oldWidget._deprecatedRenderView == widget._deprecatedRenderView);
  }

  // Hooks provided by an ancestor for this view.
  late ViewHooks _ancestorHooks;
  // Hooks provided by this view for descendant views.
  late ViewHooks _descendantHooks;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ancestorHooks = ViewHooks.of(context);
    _descendantHooks = _ancestorHooks.copyWith(pipelineOwner: _effectivePipelineOwner);
  }

  @override
  Widget build(BuildContext context) {
    return _ViewRenderObjectWidget(
      view: widget.view,
      hooks: _ancestorHooks,
      pipelineOwner: _effectivePipelineOwner,
      deprecatedRenderView: widget._deprecatedRenderView,
      child: _ViewScope(
        view: widget.view,
        child: ViewHooksScope(
          hooks: _descendantHooks,
          child: MediaQuery.fromView(
            view: widget.view,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _ViewRenderObjectWidget extends SingleChildRenderObjectWidget {
  _ViewRenderObjectWidget({
    required this.view,
    required this.hooks,
    required this.pipelineOwner,
    this.deprecatedRenderView,
    required super.child,
  }) : assert(deprecatedRenderView == null || deprecatedRenderView.flutterView == view);

  final FlutterView view;
  final ViewHooks hooks;
  final PipelineOwner pipelineOwner;
  final RenderView? deprecatedRenderView;

  @override
  SingleChildRenderObjectElement createElement() => _ViewRenderObjectWidgetElement(this);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return deprecatedRenderView ?? RenderView(
      view: view,
    );
  }

  // No need to implement updateRenderObject: The View widget uses the view as a
  // GlobalKey, so we never need to update the RenderObject with a new view.
}

class _ViewRenderObjectWidgetElement extends RootSingleChildRenderObjectElementMixin {
  _ViewRenderObjectWidgetElement(super.widget);

  @override
  RenderView get renderObject => super.renderObject as RenderView;

  @override
  void mount(Element? parent, Object? newSlot) {
    // TODO(goderbauer): why do we need this? - Views are only allowed in certain places.
    // assert(newSlot == View.viewSlot);
    final _ViewRenderObjectWidget viewWidget = widget as _ViewRenderObjectWidget;
    super.mount(parent, newSlot); // calls attachRenderObject(), updates slot memeber.
    renderObject.prepareInitialFrame();
    if (viewWidget.pipelineOwner.semanticsOwner != null) {
      renderObject.scheduleInitialSemantics();
    }
  }

  bool _attached = false;

  @override
  void attachRenderObject(Object? newSlot) {
    // assert(newSlot == View.viewSlot);
    final _ViewRenderObjectWidget viewWidget = widget as _ViewRenderObjectWidget;
    viewWidget.hooks.pipelineOwner.adoptChild(viewWidget.pipelineOwner);
    assert(viewWidget.pipelineOwner.rootNode == null);
    viewWidget.pipelineOwner.rootNode = renderObject;
    viewWidget.hooks.renderViewRepository.addRenderView(renderObject);
    _attached = true;
    super.attachRenderObject(newSlot); // updates slot member
  }

  @override
  void detachRenderObject() {
    final _ViewRenderObjectWidget viewWidget = widget as _ViewRenderObjectWidget;
    if (!_attached) {
      // In global key move scenarios `detachRenderObject` is called twice.
      assert(viewWidget.pipelineOwner.rootNode == null);
      return;
    }
    viewWidget.hooks.renderViewRepository.removeRenderView(renderObject);
    assert(viewWidget.pipelineOwner.rootNode == renderObject);
    viewWidget.pipelineOwner.rootNode = null;
    viewWidget.hooks.pipelineOwner.dropChild(viewWidget.pipelineOwner);
    _attached = false;
    super.detachRenderObject(); // updates slot member
  }

  @override
  void update(_ViewRenderObjectWidget oldWidget) {
    super.update(oldWidget);
    final _ViewRenderObjectWidget viewWidget = widget as _ViewRenderObjectWidget;
    assert(oldWidget.deprecatedRenderView == viewWidget.deprecatedRenderView);
    assert(oldWidget.pipelineOwner == viewWidget.pipelineOwner);
    final ViewHooks oldHooks = oldWidget.hooks;
    final ViewHooks newHooks = viewWidget.hooks;
    if (oldHooks.pipelineOwner != newHooks.pipelineOwner) {
      oldHooks.pipelineOwner.dropChild(viewWidget.pipelineOwner);
      newHooks.pipelineOwner.adoptChild(viewWidget.pipelineOwner);
    }
    if (oldHooks.renderViewRepository != newHooks.renderViewRepository) {
      oldHooks.renderViewRepository.removeRenderView(renderObject);
      newHooks.renderViewRepository.addRenderView(renderObject);
    }
  }
}

class _ViewScope extends InheritedWidget {
  const _ViewScope({required this.view, required super.child});

  final FlutterView view;

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
