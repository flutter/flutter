// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'floating_action_button.dart';
import 'floating_action_button_location.dart';
import 'page.dart';

typedef MasterViewBuilder = Widget Function(
  BuildContext context,
  bool isLateralUI,
);

typedef DetailPageBuilder = Widget Function(
  BuildContext context,
  Object arguments,
  ScrollController scrollController,
);

typedef ActionBuilder = List<Widget> Function(
  BuildContext context,
  ActionLevel actionLevel,
);

/// Describes which type of app bar the actions are intended for.
enum ActionLevel {
  /// Indicates the top app bar in the lateral UI.
  top,

  /// Indicates the master view app bar in the lateral UI.
  view,

  /// Indicates the master page app bar in the nested UI.
  composite,
}

/// Describes which layout will be used by [MasterDetailFlow].
enum LayoutMode {
  /// Use a nested or lateral layout depending on available screen width.
  auto,

  /// Always use a lateral layout.
  lateral,

  /// Always use a nested layout.
  nested,
}

const String _navMaster = 'master';
const String _navDetail = 'detail';
enum _Focus { master, detail }

/// A Master Detail Flow widget. Depending on screen width it builds either a lateral or nested
/// navigation flow between a master view and a detail page.
/// bloc pattern.
///
/// If focus is on detail view, then switching to nested
/// navigation will populate the navigation history with the master page and the detail page on
/// top. Otherwise the focus is on the master view and just the master page is shown.
class MasterDetailFlow extends StatefulWidget {
  /// Creates a master detail navigation flow which is either nested or lateral depending on
  /// screen width.
  const MasterDetailFlow({
    Key key,
    @required this.detailPageBuilder,
    @required this.masterViewBuilder,
    this.actionBuilder,
    this.automaticallyImplyLeading = true,
    this.breakpoint,
    this.centerTitle,
    this.detailPageFABGutterWidth,
    this.detailPageFABlessGutterWidth,
    this.displayMode = LayoutMode.auto,
    this.flexibleSpace,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.floatingActionButtonMasterPageLocation,
    this.leading,
    this.masterPageBuilder,
    this.masterViewWidth,
    this.title,
  })  : assert(masterViewBuilder != null),
        assert(automaticallyImplyLeading != null),
        assert(detailPageBuilder != null),
        assert(displayMode != null),
        super(key: key);

  /// Builder for the master view for lateral navigation.
  ///
  /// If [masterPageBuilder] is not supplied the master page required for nested navigation, also
  /// builds the master view inside a [Scaffold] with an [AppBar].
  final MasterViewBuilder masterViewBuilder;

  /// Builder for the master page for nested navigation.
  ///
  /// This builder is usually a wrapper around the [masterViewBuilder] builder to provide the
  /// extra UI required to make a page. However, this builder is optional, and the master page
  /// can be built using the master view builder and the configuration for the lateral UI's app bar.
  final MasterViewBuilder masterPageBuilder;

  /// Builder for the detail page.
  ///
  /// If scrollController == null, the page is intended for nested navigation. The lateral detail
  /// page is inside a [DraggableScrollableSheet] and should have a scrollable element that uses
  /// the [ScrollController] provided. In fact, it is strongly recommended the entire lateral
  /// page is scrollable.
  final DetailPageBuilder detailPageBuilder;

  /// Override the width of the master view in the lateral UI.
  final double masterViewWidth;

  /// Override the width of the floating action button gutter in the lateral UI.
  final double detailPageFABGutterWidth;

  /// Override the width of the gutter when there is no floating action button.
  final double detailPageFABlessGutterWidth;

  /// Add a floating action button to the lateral UI. If no [masterPageBuilder] is supplied, this
  /// floating action button is also used on the nested master page.
  ///
  /// See [Scaffold.floatingActionButton].
  final FloatingActionButton floatingActionButton;

  /// The title for the lateral UI [AppBar].
  ///
  /// See [AppBar.title].
  final Widget title;

  /// A widget to display before the title for the lateral UI [AppBar].
  ///
  /// See [AppBar.leading].
  final Widget leading;

  /// Override the framework from determining whether to show a leading widget or not.
  ///
  /// See [AppBar.automaticallyImplyLeading].
  final bool automaticallyImplyLeading;

  /// Override the framework from determining whether to display the title in the centre of the
  /// app bar or not.
  ///
  /// See [AppBar.centerTitle].
  final bool centerTitle;

  /// See [AppBar.flexibleSpace].
  final Widget flexibleSpace;

  /// Build actions for the lateral UI, and potentially the master page in the nested UI.
  ///
  /// If level is [ActionLevel.top] then the actions are for
  /// the entire lateral UI page. If level is [ActionLevel.view] the actions are for the master
  /// view toolbar. Finally, if the [AppBar] for the master page for the nested UI is being built
  /// by [MasterDetailFlow], then [ActionLevel.composite] indicates the actions are for the
  /// nested master page.
  final ActionBuilder actionBuilder;

  /// Determine where the floating action button will go.
  ///
  /// If null, [FloatingActionButtonLocation.endTop] is used.
  ///
  /// Also see [Scaffold.floatingActionButtonLocation].
  final FloatingActionButtonLocation floatingActionButtonLocation;

  /// Determine where the floating action button will go on the master page.
  ///
  /// See [Scaffold.floatingActionButtonLocation].
  final FloatingActionButtonLocation floatingActionButtonMasterPageLocation;

  /// Forces display mode and style.
  final LayoutMode displayMode;

  /// Width at which layout changes from nested to lateral.
  final double breakpoint;

  @override
  _MasterDetailFlowState createState() => _MasterDetailFlowState();

  /// The master detail flow proxy from the closest instance of this class that encloses the given
  /// context.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// MasterDetailFlow.of(context).openDetailPage(arguments);
  /// ```
  static MasterDetailFlowProxy of(
    BuildContext context, {
    bool nullOk = false,
  }) {
    _PageOpener pageOpener =
        context.findAncestorStateOfType<_MasterDetailScaffoldState>();
    pageOpener ??= context.findAncestorStateOfType<_MasterDetailFlowState>();
    assert(() {
      if (pageOpener == null && !nullOk) {
        throw FlutterError(
            'Master Detail operation requested with a context that does not include a Master Detail'
            ' Flow.\nThe context used to open a detail page from the Master Detail Flow must be'
            ' that of a widget that is a descendant of a Master Detail Flow widget.');
      }
      return true;
    }());
    return pageOpener != null ? MasterDetailFlowProxy._(pageOpener) : null;
  }
}

/// Interface for interacting with the [MasterDetailFlow].
class MasterDetailFlowProxy implements _PageOpener {
  MasterDetailFlowProxy._(this._pageOpener);

  final _PageOpener _pageOpener;

  /// Open detail page with arguments.
  @override
  void openDetailPage(Object arguments) =>
      _pageOpener.openDetailPage(arguments);

  /// Set the initial page to be open for the lateral layout. This can be set at any time, but
  /// will have no effect after any calls to openDetailPage.
  @override
  void setInitialDetailPage(Object arguments) =>
      _pageOpener.setInitialDetailPage(arguments);
}

abstract class _PageOpener {
  void openDetailPage(Object arguments);

  void setInitialDetailPage(Object arguments);
}

class _MasterDetailFlowState extends State<MasterDetailFlow>
    implements _PageOpener {
  /// Tracks whether focus is on the detail or master views. Determines behaviour when switching
  /// from lateral to nested navigation.
  _Focus focus = _Focus.master;

  /// Cache of arguments passed when opening a detail page. Used when rebuilding.
  Object _cachedDetailArguments;

  /// Record of the layout that was built.
  LayoutMode _builtLayout;

  /// Key to access navigator in the nested layout.
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void openDetailPage(Object arguments) {
    _cachedDetailArguments = arguments;
    if (_builtLayout == LayoutMode.nested) {
      _navigatorKey.currentState.pushNamed(_navDetail, arguments: arguments);
    } else {
      focus = _Focus.detail;
    }
  }

  @override
  void setInitialDetailPage(Object arguments) {
    _cachedDetailArguments = arguments;
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.displayMode) {
      case LayoutMode.nested:
        return _buildNestedUI(context);
      case LayoutMode.lateral:
        return _buildLateralUI(context);
      case LayoutMode.auto:
      default:
        return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
          final double availableWidth = constraints.maxWidth;
          if (availableWidth >= (widget.breakpoint ?? 840)) {
            return _buildLateralUI(context);
          } else {
            return _buildNestedUI(context);
          }
        });
    }
  }

  Widget _buildNestedUI(BuildContext context) {
    _builtLayout = LayoutMode.nested;
    return Navigator(
      key: _navigatorKey,
      initialRoute: 'initial',
      onGenerateInitialRoutes: (NavigatorState navigator, String initialRoute) {
        switch (focus) {
          case _Focus.master:
            return <Route<dynamic>>[
              MaterialPageRoute<dynamic>(
                builder: widget.masterPageBuilder != null
                    ? (BuildContext c) =>
                        widget.masterPageBuilder(c, false)
                    : (BuildContext c) => _buildMasterPage(c, context),
              ),
            ];
          default:
            return <Route<dynamic>>[
              MaterialPageRoute<dynamic>(
                builder: widget.masterPageBuilder != null
                    ? (BuildContext c) =>
                        widget.masterPageBuilder(c, false)
                    : (BuildContext c) => _buildMasterPage(c, context),
              ),
              MaterialPageRoute<dynamic>(
                builder: (BuildContext context) => WillPopScope(
                  child: widget.detailPageBuilder(
                    context,
                    _cachedDetailArguments,
                    null,
                  ),
                  onWillPop: () async {
                    // No need for setState() as rebuild happens on navigation pop.
                    focus = _Focus.master;
                    Navigator.of(context).pop();
                    return false;
                  },
                ),
              )
            ];
        }
      },
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case _navMaster:
            // Matching state to navigation event.
            focus = _Focus.master;
            return MaterialPageRoute<void>(
              builder: widget.masterPageBuilder != null
                  ? (BuildContext context) =>
                      widget.masterPageBuilder(context, false)
                  : (BuildContext c) => _buildMasterPage(c, context),
            );
          case _navDetail:
            // Matching state to navigation event.
            focus = _Focus.detail;
            // Cache detail page settings.
            _cachedDetailArguments = settings.arguments;
            return MaterialPageRoute<void>(
              builder: (BuildContext context) => WillPopScope(
                child: widget.detailPageBuilder(
                  context,
                  _cachedDetailArguments,
                  null,
                ),
                onWillPop: () async {
                  // No need for setState() as rebuild happens on navigation pop.
                  focus = _Focus.master;
                  Navigator.of(context).pop();
                  return false;
                },
              ),
            );
          default:
            throw Exception('Unknown route ${settings.name}');
        }
      },
    );
  }

  /// Build a master page using the master view builder.
  ///
  /// Uses the context (flowContext) from the MasterDetailFlow widget to pop
  /// the nav route if there is no back button supplied.
  Widget _buildMasterPage(BuildContext context, BuildContext flowContext) {
    return Scaffold(
      appBar: AppBar(
        title: widget.title,
        leading: widget.leading ??
            (widget.automaticallyImplyLeading && Navigator.of(flowContext).canPop()
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(flowContext).pop(),
                  )
                : null),
        actions: widget.actionBuilder == null
            ? const <Widget>[]
            : widget.actionBuilder(context, ActionLevel.composite),
        centerTitle: widget.centerTitle,
        flexibleSpace: widget.flexibleSpace,
      ),
      body: widget.masterViewBuilder(context, false),
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
    );
  }

  Widget _buildLateralUI(BuildContext context) {
    _builtLayout = LayoutMode.lateral;
    return _MasterDetailScaffold(
      actionBuilder: widget.actionBuilder ??
          (BuildContext context, ActionLevel actionLevel) => const <Widget>[],
      automaticallyImplyLeading: widget.automaticallyImplyLeading,
      centerTitle: widget.centerTitle,
      detailPageBuilder: (BuildContext context, Object arguments,
              ScrollController scrollController) =>
          widget.detailPageBuilder(
        context,
        arguments ?? _cachedDetailArguments,
        scrollController,
      ),
      floatingActionButton: widget.floatingActionButton,
      detailPageFABlessGutterWidth: widget.detailPageFABlessGutterWidth,
      detailPageFABGutterWidth: widget.detailPageFABGutterWidth,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
      initialArguments: _cachedDetailArguments,
      leading: widget.leading,
      masterViewBuilder: (BuildContext context, bool isLateral) =>
          widget.masterViewBuilder(context, isLateral),
      masterViewWidth: widget.masterViewWidth,
      title: widget.title,
    );
  }
}

const double _kCardElevation = 4;
const double _kMasterViewWidth = 320;
const double _kDetailPageFABlessGutterWidth = 40;
const double _kDetailPageFABGutterWidth = 84;

class _MasterDetailScaffold extends StatefulWidget {
  const _MasterDetailScaffold({
    Key key,
    @required this.detailPageBuilder,
    @required this.masterViewBuilder,
    this.actionBuilder,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.initialArguments,
    this.leading,
    this.title,
    this.automaticallyImplyLeading,
    this.centerTitle,
    this.detailPageFABlessGutterWidth,
    this.detailPageFABGutterWidth,
    this.masterViewWidth,
  })  : assert(detailPageBuilder != null),
        assert(masterViewBuilder != null),
        super(key: key);

  final MasterViewBuilder masterViewBuilder;

  /// Builder for the detail page.
  ///
  /// The detail page is inside a [DraggableScrollableSheet] and should have a scrollable element
  /// that uses the [ScrollController] provided. In fact, it is strongly recommended the entire
  /// lateral page is scrollable.
  final DetailPageBuilder detailPageBuilder;
  final ActionBuilder actionBuilder;
  final FloatingActionButton floatingActionButton;
  final FloatingActionButtonLocation floatingActionButtonLocation;
  final Object initialArguments;
  final Widget leading;
  final Widget title;
  final bool automaticallyImplyLeading;
  final bool centerTitle;
  final double detailPageFABlessGutterWidth;
  final double detailPageFABGutterWidth;
  final double masterViewWidth;

  @override
  _MasterDetailScaffoldState createState() => _MasterDetailScaffoldState();
}

class _MasterDetailScaffoldState extends State<_MasterDetailScaffold>
    implements _PageOpener {
  FloatingActionButtonLocation floatingActionButtonLocation;
  double detailPageFABGutterWidth;
  double detailPageFABlessGutterWidth;
  double masterViewWidth;

  final ValueNotifier<Object> _detailArguments = ValueNotifier<Object>(null);

  @override
  void initState() {
    super.initState();
    detailPageFABlessGutterWidth =
        widget.detailPageFABlessGutterWidth ?? _kDetailPageFABlessGutterWidth;
    detailPageFABGutterWidth =
        widget.detailPageFABGutterWidth ?? _kDetailPageFABGutterWidth;
    masterViewWidth = widget.masterViewWidth ?? _kMasterViewWidth;
    floatingActionButtonLocation = widget.floatingActionButtonLocation ??
        FloatingActionButtonLocation.endTop;
  }

  @override
  void openDetailPage(Object arguments) {
    SchedulerBinding.instance
        .addPostFrameCallback((_) => _detailArguments.value = arguments);
    MasterDetailFlow.of(context).openDetailPage(arguments);
  }

  @override
  void setInitialDetailPage(Object arguments) {
    SchedulerBinding.instance
        .addPostFrameCallback((_) => _detailArguments.value = arguments);
    MasterDetailFlow.of(context).setInitialDetailPage(arguments);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Scaffold(
          floatingActionButtonLocation: floatingActionButtonLocation,
          appBar: AppBar(
            title: widget.title,
            actions: widget.actionBuilder(context, ActionLevel.top),
            leading: widget.leading,
            automaticallyImplyLeading: widget.automaticallyImplyLeading,
            centerTitle: widget.centerTitle,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  ConstrainedBox(
                    constraints:
                        BoxConstraints.tightFor(width: masterViewWidth),
                    child: IconTheme(
                      data: Theme.of(context).primaryIconTheme,
                      child: ButtonBar(
                        children:
                            widget.actionBuilder(context, ActionLevel.view),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          body: _buildMasterPanel(context),
          floatingActionButton: widget.floatingActionButton,
        ),
        // Detail view stacked above main scaffold and master view.
        SafeArea(
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: masterViewWidth - _kCardElevation,
              end: widget.floatingActionButton == null
                  ? detailPageFABlessGutterWidth
                  : detailPageFABGutterWidth,
            ),
            child: ValueListenableBuilder<Object>(
              valueListenable: _detailArguments,
              builder: (BuildContext context, Object value, Widget child) {
                return AnimatedSwitcher(
                  transitionBuilder:
                      (Widget child, Animation<double> animation) =>
                          const FadeUpwardsPageTransitionsBuilder()
                              .buildTransitions<void>(
                                  null, null, animation, null, child),
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    key: ValueKey<Object>(value ?? widget.initialArguments),
                    constraints: const BoxConstraints.expand(),
                    child: _DetailView(
                      builder: widget.detailPageBuilder,
                      arguments: value ?? widget.initialArguments,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  ConstrainedBox _buildMasterPanel(
    BuildContext context, {
    bool needsScaffold = false,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: masterViewWidth),
      child: needsScaffold
          ? Scaffold(
              appBar: AppBar(
                title: widget.title,
                actions: widget.actionBuilder(context, ActionLevel.top),
                leading: widget.leading,
                automaticallyImplyLeading: widget.automaticallyImplyLeading,
                centerTitle: widget.centerTitle,
              ),
              body: widget.masterViewBuilder(context, true))
          : widget.masterViewBuilder(context, true),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({
    Key key,
    @required DetailPageBuilder builder,
    Object arguments,
  })  : assert(builder != null),
        _builder = builder,
        _arguments = arguments,
        super(key: key);

  final DetailPageBuilder _builder;
  final Object _arguments;

  @override
  Widget build(BuildContext context) {
    if (_arguments == null) {
      return Container();
    }
    final double screenHeight = MediaQuery.of(context).size.height;
    final double minHeight = (screenHeight - kToolbarHeight) / screenHeight;

    return GestureDetector(
      onTap: () {
        print('draggable');
      },
      behavior: HitTestBehavior.deferToChild,
      child: DraggableScrollableSheet(
        initialChildSize: minHeight,
        minChildSize: minHeight,
        maxChildSize: 1,
        expand: false,
        builder: (BuildContext context, ScrollController controller) {
          return MouseRegion(
            // Workaround bug where things behind sheet still get mouse hover events.
            child: Card(
              color: Theme.of(context).cardColor,
              elevation: _kCardElevation,
              clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.fromLTRB(
                  _kCardElevation, 0, _kCardElevation, 0),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(3), bottom: Radius.zero),
              ),
              child: _builder(
                context,
                _arguments,
                controller,
              ),
            ),
          );
        },
      ),
    );
  }
}
