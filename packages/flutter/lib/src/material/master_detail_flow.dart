// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'app_bar.dart';
import 'back_button.dart';
import 'card.dart';
import 'constants.dart';
import 'floating_action_button_location.dart';
import 'ink_decoration.dart';
import 'list_tile.dart';
import 'material.dart';
import 'page.dart';
import 'page_transitions_theme.dart';
import 'scaffold.dart';
import 'scrollbar.dart';
import 'theme.dart';

const int _materialGutterThreshold = 720;
const double _wideGutterSize = 24.0;
const double _narrowGutterSize = 12.0;

double _getGutterSize(BuildContext context) =>
    MediaQuery.of(context).size.width >= _materialGutterThreshold
        ? _wideGutterSize
        : _narrowGutterSize;

/// Signature for the builder callback used by [MasterDetailFlow].
typedef MasterViewBuilder = Widget Function(
    BuildContext context, bool isLateralUI);

/// Signature for the builder callback used by [MasterDetailFlow.detailPageBuilder].
///
/// scrollController is provided when the page destination is the draggable
/// sheet in the lateral UI. Otherwise, it is null.
typedef DetailPageBuilder = Widget Function(BuildContext context,
    Object? arguments, ScrollController? scrollController);

/// Signature for the list of MasterDetailsFlowItemBase used by [MasterDetailFlow].
typedef MasterItemsList = List<MasterDetailFlowItemBase>;

/// Signature for the builder callback used by [MasterDetailFlow.actionBuilder].
///
/// Builds the actions that go in the app bars constructed for the master and
/// lateral UI pages. actionLevel indicates the intended destination of the
/// return actions.
typedef _ActionBuilder = List<Widget> Function(
    BuildContext context, _ActionLevel actionLevel);

/// Describes which type of app bar the actions are intended for.
enum _ActionLevel {
  /// Indicates the top app bar in the lateral UI.
  top,

  /// Indicates the master view app bar in the lateral UI.
  view,
}

const String _navMaster = 'master';
const String _navDetail = 'detail';

enum _Focus { master, detail }

/// Describes which layout will be used by [MasterDetailFlow].
enum MasterDetailFlowLayoutMode {
  /// Use a nested or lateral layout depending on available screen width.
  auto,

  /// Always use a lateral layout.
  lateral,

  /// Always use a nested layout.
  nested,
}

/// A base class for entries in a Material Design MasterDetailsFlow.
///
/// A [MasterDetailFlowItemBase] may represent a title (see
/// [MasterDetailFlowTitle]), a divider (see [MasterDetailFlowDivider]) or a
/// list tile that opens details([MasterDetailFlowItem]).
///
/// See also:
///
///  * [MasterDetailFlowTitle], a master detail flow entry that is a title.
///  * [MasterDetailFlowItem], a list tile that opens details pages.
///  * [MasterDetailFlowDivider], a master detail flow entry that is just a
///  simple divider.
abstract class MasterDetailFlowItemBase {
  /// Abstract const constructor.
  const MasterDetailFlowItemBase({
    required this.selectable,
  });

  /// Defines if this is an item that can open a details page.
  final bool selectable;

  /// This builds the widget that is shown in the master panel. You can override
  /// this to create custom widgets(if you want to create a selectable item
  /// extend MasterDetailFlowItem instead).
  /// [selected] and [onTap] are used only in selectable items.
  Widget buildWidget(BuildContext context,
      {bool selected = false, GestureTapCallback? onTap});
}

/// A widget that can be placed in a MasterDetailFlow master panel with a title
/// and subtitle that opens a details page when tapped.
///
/// ```dart
/// masterItems: [
///   MasterDetailFlowItem(
///       title: Text('Some amazing title'),
///       subtitle: Text('And a subtitle'),
///       showSubtitleOnDetails: true,
///       detailsListChildBuilder: (context, index) =>
///           Text('Child $index'),
///     ),
/// ]
/// ```
///
/// See also:
///
///  * [MasterDetailFlowTitle], a master detail flow entry that is a title.
///  * [MasterDetailFlowDivider], a master detail flow entry that is just a
///  simple divider.
class MasterDetailFlowItem extends MasterDetailFlowItemBase {
  /// Creates a MasterDetailFlowItem.
  const MasterDetailFlowItem({
    this.key,
    required this.title,
    this.subtitle,
    this.showSubtitleOnDetails = false,
    this.leading,
    this.trailing,
    required this.detailsListChildBuilder,
    this.detailsChildrenCount,
  })  : assert(detailsChildrenCount == null || detailsChildrenCount >= 0),
        super(
          selectable: true,
        );

  /// Key for the master widget
  final Key? key;

  /// The title widget that is shown in the list and as the title of the details
  /// page
  ///
  /// Typically a [Text] widget.
  final Widget title;

  /// Additional content displayed below the title in the list, but also on the
  /// details page if showSubtitleOnDetails is set to true.
  ///
  /// Typically a [Text] widget.
  final Widget? subtitle;

  /// A widget to display before the title.
  ///
  /// Typically an [Icon] or a [CircleAvatar] widget.
  final Widget? leading;

  /// A widget to display after the title.
  ///
  /// Typically an [Icon] widget.
  final Widget? trailing;

  /// If set to true the subtitle is displayed below the title on the details
  /// page.
  final bool showSubtitleOnDetails;

  /// A function used to create children on demand in the details page. For more
  /// information you can also see [ListView.builder]
  ///
  /// The `detailsListChildBuilder` callback will be called only with indices greater than
  /// or equal to zero and less than `detailsChildrenCount`.
  ///
  /// The `detailsListChildBuilder` should always return a non-null widget, and actually
  /// create the widget instances when called. Avoid using a builder that
  /// returns a previously-constructed widget.
  final Widget Function(BuildContext context, int index)
      detailsListChildBuilder;

  /// Providing a non-null `detailsChildrenCount` improves the ability of the
  /// [ListView] inside of the details page to estimate the maximum scroll
  /// extent. If 'detailsChildrenCount' is set to 1 the children will be build
  /// outside of any ListView. See more [ListView.builder].
  final int? detailsChildrenCount;

  @override
  Widget buildWidget(BuildContext context,
      {bool selected = false, GestureTapCallback? onTap}) {
    assert(onTap != null, 'onTap must be specified for a MasterDetailFlowItem');
    return Ink(
      color: selected ? Theme.of(context).highlightColor : null,
      child: ListTile(
        key: key,
        title: title,
        subtitle: subtitle,
        onTap: onTap,
        leading: leading,
        trailing: trailing,
        selected: selected,
      ),
    );
  }
}

/// A master detail flow entry that can be used as title. 'child' can be
/// any type of Widget.
///
/// ```dart
///  masterItems: [
///     MasterDetailFlowTitle(
///       child: Container(
///         color: Colors.green,
///         height: 200,
///         child: const Center(
///           child: Text('Title'),
///         ),
///       ),
///     ),
///  ],
/// ```
///
/// See also:
///
///  * [MasterDetailFlowItem], a list tile that opens details.
///  * [MasterDetailFlowDivider], a master detail flow entry that is just a
///  simple divider.
class MasterDetailFlowTitle extends MasterDetailFlowItemBase {
  /// Creates the MasterDetailFlowTitle
  const MasterDetailFlowTitle({
    required this.child,
  }) : super(
          selectable: false,
        );

  /// The [child] contained by the MasterDetailFlowTitle.
  final Widget child;

  @override
  Widget buildWidget(BuildContext context,
      {bool selected = false, GestureTapCallback? onTap}) {
    return child;
  }
}

/// A master detail flow entry that is a simple divider for the other
/// MasterDetailFlow items.
///
/// See also:
///
///  * [MasterDetailFlowTitle], a master detail flow entry that is a title.
///  * [MasterDetailFlowItem], a list tile that open a details page.
class MasterDetailFlowDivider extends MasterDetailFlowItemBase {
  /// Creates a diver for MasterDetailFlow
  const MasterDetailFlowDivider({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  }) : super(selectable: false);

  /// The divider widget. Usually a [Divider] or [Text]
  final Widget child;

  /// The amount of space by which to inset the child.
  final EdgeInsets? padding;

  @override
  Widget buildWidget(BuildContext context,
      {bool selected = false, GestureTapCallback? onTap}) {
    return DefaultTextStyle(
      style: Theme.of(context).textTheme.labelMedium!,
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      ),
    );
  }
}

/// Just a class to pass arguments to a details page
@immutable
class _MDFArguments {
  const _MDFArguments(this.itemIndex);
  final int itemIndex;

  @override
  bool operator ==(final dynamic other) {
    if (other is _MDFArguments) {
      return other.itemIndex == itemIndex;
    }
    return other == this;
  }

  @override
  int get hashCode => itemIndex.hashCode;
}

/// A Master Detail Flow widget. Depending on screen width it builds either a
/// lateral or nested navigation flow between a master view and a detail page.
///
/// ```dart
/// MasterDetailFlow.fromItems(
///   title: const Text('MasterDetailFlow'),
///   masterItems: <MasterDetailFlowItemBase>[
///     MasterDetailFlowItem(
///       title: Text('Option One'),
///       detailsListChildBuilder: (context, index) =>
///           Text('Hello World $index'),
///     ),
///     const MasterDetailFlowDivider(child: Divider()),
///   ],
/// ),
/// ```
///
/// See also:
///
///  * [MasterDetailFlowTitle], a master detail flow entry that is a title.
///  * [MasterDetailFlowItem], a list tile that opens details pages.
///  * [MasterDetailFlowDivider], a master detail flow entry that is just a
///  simple divider.
class MasterDetailFlow extends StatefulWidget {
  /// Creates a master detail navigation flow which is either nested or
  /// lateral depending on screen width from [masterViewBuilder] and
  /// [detailPageBuilder]. Preferably use [MasterDetailFlow.fromItems]
  const MasterDetailFlow({
    super.key,
    required DetailPageBuilder this.detailPageBuilder,
    required MasterViewBuilder this.masterViewBuilder,
    this.automaticallyImplyLeading = true,
    this.detailPageFABlessGutterWidth,
    this.displayMode = MasterDetailFlowLayoutMode.auto,
    this.title,
  })  : masterItems = null,
        assert(detailPageBuilder != null),
        assert(masterViewBuilder != null),
        assert(automaticallyImplyLeading != null),
        assert(displayMode != null);

  /// Creates a master detail navigation flow which is either nested or
  /// lateral depending on screen width from a list of [MasterDetailFlowItemBase]
  const MasterDetailFlow.fromItems({
    super.key,
    required MasterItemsList this.masterItems,
    this.automaticallyImplyLeading = true,
    this.detailPageFABlessGutterWidth,
    this.displayMode = MasterDetailFlowLayoutMode.auto,
    this.title,
  })  : masterViewBuilder = null,
        detailPageBuilder = null,
        assert(masterItems != null),
        assert(automaticallyImplyLeading != null),
        assert(displayMode != null);

  /// Builder for the master view for lateral navigation.
  ///
  /// If masterViewBuilder is not supplied the master page required for nested
  /// navigation, also builds the master view inside a [Scaffold] with an [AppBar].
  final MasterViewBuilder? masterViewBuilder;

  /// The list of items from which the MasterDetailFlow is constructed
  final MasterItemsList? masterItems;

  /// Builder for the detail page.
  ///
  /// If scrollController == null, the page is intended for nested navigation.
  /// The lateral detail page is inside a [DraggableScrollableSheet] and should
  /// have a scrollable element that uses the [ScrollController] provided. In
  /// fact, it is strongly recommended the entire lateral page is scrollable.
  final DetailPageBuilder? detailPageBuilder;

  /// Override the width of the gutter when there is no floating action button.
  final double? detailPageFABlessGutterWidth;

  /// The title for the lateral UI [AppBar].
  ///
  /// See [AppBar.title].
  final Widget? title;

  /// Override the framework from determining whether to show a leading widget
  /// or not.
  ///
  /// See [AppBar.automaticallyImplyLeading].
  final bool automaticallyImplyLeading;

  /// Forces display mode and style.
  final MasterDetailFlowLayoutMode displayMode;

  @override
  MasterDetailFlowState createState() => MasterDetailFlowState();

  /// The master detail flow proxy from the closest instance of this class that
  /// encloses the given context.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// _MasterDetailFlow.of(context).openDetailPage(arguments);
  /// ```
  static MasterDetailFlowProxy? of(BuildContext context) {
    _PageOpener? pageOpener =
        context.findAncestorStateOfType<_MasterDetailScaffoldState>();
    pageOpener ??= context.findAncestorStateOfType<MasterDetailFlowState>();
    assert(() {
      if (pageOpener == null) {
        throw FlutterError(
          'Master Detail operation requested with a context that does not '
          'include a Master Detail Flow.\nThe context used to open a detail page '
          'from the Master Detail Flow must be that of a widget that is a '
          'descendant of a Master Detail Flow widget.',
        );
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

  /// Set the initial page to be open for the lateral layout. This can be set at
  /// any time, but will have no effect after any calls to openDetailPage.
  @override
  void setInitialDetailPage(Object arguments) =>
      _pageOpener.setInitialDetailPage(arguments);
}

abstract class _PageOpener {
  void openDetailPage(Object arguments);

  void setInitialDetailPage(Object arguments);
}

const int _materialWideDisplayThreshold = 840;

/// The state of the MasterDetailFlow. Can be used to open details pages.
class MasterDetailFlowState extends State<MasterDetailFlow>
    implements _PageOpener {
  /// Tracks whether focus is on the detail or master views. Determines behavior when switching
  /// from lateral to nested navigation.
  _Focus _focus = _Focus.master;

  /// Cache of arguments passed when opening a detail page. Used when rebuilding.
  Object? _cachedDetailArguments;

  /// Record of the layout that was built.
  MasterDetailFlowLayoutMode? _builtLayout;

  /// Key to access navigator in the nested layout.
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  final ValueNotifier<int?> _selectedId = ValueNotifier<int?>(null);
  late MasterViewBuilder _masterViewBuilder;
  late DetailPageBuilder _detailPageBuilder;

  @override
  void initState() {
    super.initState();
    if (widget.detailPageBuilder != null && widget.masterViewBuilder != null) {
      _detailPageBuilder = widget.detailPageBuilder!;
      _masterViewBuilder = widget.masterViewBuilder!;
    } else {
      assert(widget.masterItems != null);
      final MasterItemsList masterItems = widget.masterItems!;
      _masterViewBuilder = (BuildContext context, bool isLateralUI) {
        return ListView.builder(
          itemBuilder: (BuildContext context, int index) {
            return ValueListenableBuilder<int?>(
              valueListenable: _selectedId,
              builder: (BuildContext context, Object? value, Widget? child) =>
                  masterItems[index].buildWidget(context,
                      selected: index == (value ?? -1) &&
                          masterItems[index].selectable &&
                          isLateralUI,
                      onTap: masterItems[index].selectable
                          ? () {
                              _selectedId.value = index;
                              MasterDetailFlow.of(context)!
                                  .openDetailPage(_MDFArguments(index));
                            }
                          : null),
            );
          },
          itemCount: masterItems.length,
        );
      };
      _detailPageBuilder = (BuildContext context, Object? arguments,
          ScrollController? scrollController) {
        assert(arguments is _MDFArguments);
        final _MDFArguments args = arguments! as _MDFArguments;
        assert(masterItems[args.itemIndex] is MasterDetailFlowItem);
        final MasterDetailFlowItem item =
            masterItems[args.itemIndex] as MasterDetailFlowItem;

        final ThemeData theme = Theme.of(context);
        final Widget title = item.title;
        final Widget? subtitle = item.subtitle;
        final bool showSubtitle = item.showSubtitleOnDetails;
        final double pad = _getGutterSize(context);
        final EdgeInsets padding =
            EdgeInsets.only(left: pad, right: pad, bottom: pad);

        final Widget page;
        if (scrollController == null) {
          page = Scaffold(
            appBar: AppBar(
              title: SizedBox(
                height: theme.appBarTheme.toolbarHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    DefaultTextStyle(
                        style: theme.appBarTheme.titleTextStyle ??
                            theme.textTheme.titleLarge!.copyWith(
                                color: theme.appBarTheme.foregroundColor),
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        child: title),
                    if (subtitle != null && showSubtitle)
                      DefaultTextStyle(
                          style: theme.appBarTheme.titleTextStyle ??
                              theme.textTheme.titleMedium!.copyWith(
                                  color: theme.appBarTheme.foregroundColor),
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          child: subtitle),
                  ],
                ),
              ),
            ),
            body: Center(
              child: Material(
                color: theme.cardColor,
                elevation: 4.0,
                child: Container(
                  constraints:
                      BoxConstraints.loose(const Size.fromWidth(600.0)),
                  child: ScrollConfiguration(
                    // A Scrollbar is built-in below.
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(scrollbars: false),
                    child: Scrollbar(
                      child: item.detailsChildrenCount == 1
                          ? item.detailsListChildBuilder(context, 0)
                          : ListView.builder(
                              itemBuilder: item.detailsListChildBuilder,
                              itemCount: item.detailsChildrenCount,
                              padding: padding,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          );
        } else {
          page = CustomScrollView(
            controller: scrollController,
            slivers: <Widget>[
              SliverAppBar(
                automaticallyImplyLeading: false,
                pinned: true,
                backgroundColor: theme.cardColor,
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    DefaultTextStyle(
                        style: theme.appBarTheme.titleTextStyle ??
                            theme.textTheme.titleLarge!.copyWith(
                                color: theme.appBarTheme.foregroundColor),
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        child: title),
                    if (subtitle != null && showSubtitle)
                      DefaultTextStyle(
                          style: theme.appBarTheme.titleTextStyle ??
                              theme.textTheme.titleMedium!.copyWith(
                                  color: theme.appBarTheme.foregroundColor),
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          child: subtitle),
                  ],
                ),
              ),
              SliverPadding(
                padding: padding,
                sliver: item.detailsChildrenCount == 1
                    ? SliverFillRemaining(
                        child: item.detailsListChildBuilder(context, 0),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          item.detailsListChildBuilder,
                          childCount: item.detailsChildrenCount,
                        ),
                      ),
              ),
            ],
          );
        }
        return page;
      };
    }
  }

  /// Opens the details page with the arguments
  @override
  void openDetailPage(Object arguments) {
    _cachedDetailArguments = arguments;
    if (_builtLayout == MasterDetailFlowLayoutMode.nested) {
      _navigatorKey.currentState!.pushNamed(_navDetail, arguments: arguments);
    } else {
      _focus = _Focus.detail;
    }
  }

  @override
  void setInitialDetailPage(Object arguments) {
    _cachedDetailArguments = arguments;
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.displayMode) {
      case MasterDetailFlowLayoutMode.nested:
        return _nestedUI(context);
      case MasterDetailFlowLayoutMode.lateral:
        return _lateralUI(context);
      case MasterDetailFlowLayoutMode.auto:
        return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
          final double availableWidth = constraints.maxWidth;
          if (availableWidth >= _materialWideDisplayThreshold) {
            return _lateralUI(context);
          } else {
            return _nestedUI(context);
          }
        });
    }
  }

  Widget _nestedUI(BuildContext context) {
    _builtLayout = MasterDetailFlowLayoutMode.nested;
    final MaterialPageRoute<void> masterPageRoute = _masterPageRoute(context);

    return WillPopScope(
      // Push pop check into nested navigator.
      onWillPop: () async => !(await _navigatorKey.currentState!.maybePop()),
      child: Navigator(
        key: _navigatorKey,
        initialRoute: 'initial',
        onGenerateInitialRoutes:
            (NavigatorState navigator, String initialRoute) {
          switch (_focus) {
            case _Focus.master:
              return <Route<void>>[masterPageRoute];
            case _Focus.detail:
              return <Route<void>>[
                masterPageRoute,
                _detailPageRoute(_cachedDetailArguments),
              ];
          }
        },
        onGenerateRoute: (RouteSettings settings) {
          switch (settings.name) {
            case _navMaster:
              // Matching state to navigation event.
              _focus = _Focus.master;
              return masterPageRoute;
            case _navDetail:
              // Matching state to navigation event.
              _focus = _Focus.detail;
              // Cache detail page settings.
              _cachedDetailArguments = settings.arguments;
              return _detailPageRoute(_cachedDetailArguments);
            default:
              throw Exception('Unknown route ${settings.name}');
          }
        },
      ),
    );
  }

  MaterialPageRoute<void> _masterPageRoute(BuildContext context) {
    return MaterialPageRoute<dynamic>(
      builder: (BuildContext c) => BlockSemantics(
        child: _MasterPage(
          leading:
              widget.automaticallyImplyLeading && Navigator.of(context).canPop()
                  ? BackButton(onPressed: () => Navigator.of(context).pop())
                  : null,
          title: widget.title,
          automaticallyImplyLeading: widget.automaticallyImplyLeading,
          masterViewBuilder: _masterViewBuilder,
        ),
      ),
    );
  }

  MaterialPageRoute<void> _detailPageRoute(Object? arguments) {
    return MaterialPageRoute<dynamic>(builder: (BuildContext context) {
      return WillPopScope(
        onWillPop: () async {
          // No need for setState() as rebuild happens on navigation pop.
          _focus = _Focus.master;
          Navigator.of(context).pop();
          return false;
        },
        child:
            BlockSemantics(child: _detailPageBuilder(context, arguments, null)),
      );
    });
  }

  Widget _lateralUI(BuildContext context) {
    _builtLayout = MasterDetailFlowLayoutMode.lateral;
    return _MasterDetailScaffold(
      actionBuilder: (_, __) => const <Widget>[],
      automaticallyImplyLeading: widget.automaticallyImplyLeading,
      detailPageBuilder: (BuildContext context, Object? args,
              ScrollController? scrollController) =>
          _detailPageBuilder(
              context, args ?? _cachedDetailArguments, scrollController),
      detailPageFABlessGutterWidth: widget.detailPageFABlessGutterWidth,
      initialArguments: _cachedDetailArguments,
      masterViewBuilder: (BuildContext context, bool isLateral) =>
          _masterViewBuilder(context, isLateral),
      title: widget.title,
    );
  }
}

class _MasterPage extends StatelessWidget {
  const _MasterPage({
    this.leading,
    this.title,
    required this.masterViewBuilder,
    required this.automaticallyImplyLeading,
  });

  final MasterViewBuilder masterViewBuilder;
  final Widget? title;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: title,
        leading: leading,
        actions: const <Widget>[],
        automaticallyImplyLeading: automaticallyImplyLeading,
      ),
      body: masterViewBuilder(context, false),
    );
  }
}

const double _kCardElevation = 4.0;
const double _kMasterViewWidth = 320.0;
const double _kDetailPageFABlessGutterWidth = 40.0;
const double _kDetailPageFABGutterWidth = 84.0;

class _MasterDetailScaffold extends StatefulWidget {
  const _MasterDetailScaffold({
    required this.detailPageBuilder,
    required this.masterViewBuilder,
    this.actionBuilder,
    this.initialArguments,
    this.title,
    required this.automaticallyImplyLeading,
    this.detailPageFABlessGutterWidth,
  })  : assert(detailPageBuilder != null),
        assert(masterViewBuilder != null);

  final MasterViewBuilder masterViewBuilder;

  /// Builder for the detail page.
  ///
  /// The detail page is inside a [DraggableScrollableSheet] and should have a scrollable element
  /// that uses the [ScrollController] provided. In fact, it is strongly recommended the entire
  /// lateral page is scrollable.
  final DetailPageBuilder detailPageBuilder;
  final _ActionBuilder? actionBuilder;
  final Object? initialArguments;
  final Widget? title;
  final bool automaticallyImplyLeading;
  final double? detailPageFABlessGutterWidth;

  @override
  _MasterDetailScaffoldState createState() => _MasterDetailScaffoldState();
}

class _MasterDetailScaffoldState extends State<_MasterDetailScaffold>
    implements _PageOpener {
  late FloatingActionButtonLocation floatingActionButtonLocation;
  late double detailPageFABGutterWidth;
  late double detailPageFABlessGutterWidth;
  late double masterViewWidth;

  final ValueNotifier<Object?> _detailArguments = ValueNotifier<Object?>(null);

  @override
  void initState() {
    super.initState();
    detailPageFABlessGutterWidth =
        widget.detailPageFABlessGutterWidth ?? _kDetailPageFABlessGutterWidth;
    detailPageFABGutterWidth = _kDetailPageFABGutterWidth;
    masterViewWidth = _kMasterViewWidth;
    floatingActionButtonLocation = FloatingActionButtonLocation.endTop;
  }

  @override
  void dispose() {
    _detailArguments.dispose();
    super.dispose();
  }

  @override
  void openDetailPage(Object arguments) {
    SchedulerBinding.instance
        .addPostFrameCallback((_) => _detailArguments.value = arguments);
    MasterDetailFlow.of(context)!.openDetailPage(arguments);
  }

  @override
  void setInitialDetailPage(Object arguments) {
    SchedulerBinding.instance
        .addPostFrameCallback((_) => _detailArguments.value = arguments);
    MasterDetailFlow.of(context)!.setInitialDetailPage(arguments);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Scaffold(
          floatingActionButtonLocation: floatingActionButtonLocation,
          appBar: AppBar(
            title: widget.title,
            actions: widget.actionBuilder!(context, _ActionLevel.top),
            automaticallyImplyLeading: widget.automaticallyImplyLeading,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: Row(
                children: <Widget>[
                  ConstrainedBox(
                    constraints:
                        BoxConstraints.tightFor(width: masterViewWidth),
                    child: IconTheme(
                      data: Theme.of(context).primaryIconTheme,
                      child: Container(
                        alignment: AlignmentDirectional.centerEnd,
                        padding: const EdgeInsets.all(8),
                        child: OverflowBar(
                          spacing: 8,
                          overflowAlignment: OverflowBarAlignment.end,
                          children:
                              widget.actionBuilder!(context, _ActionLevel.view),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: _masterPanel(context),
        ),
        // Detail view stacked above main scaffold and master view.
        SafeArea(
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: masterViewWidth - _kCardElevation,
              end: detailPageFABlessGutterWidth,
            ),
            child: ValueListenableBuilder<Object?>(
              valueListenable: _detailArguments,
              builder: (BuildContext context, Object? value, Widget? child) {
                return AnimatedSwitcher(
                  transitionBuilder:
                      (Widget child, Animation<double> animation) =>
                          const FadeUpwardsPageTransitionsBuilder()
                              .buildTransitions<void>(
                    null,
                    null,
                    animation,
                    null,
                    child,
                  ),
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    key: ValueKey<Object?>(value ?? widget.initialArguments),
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

  ConstrainedBox _masterPanel(BuildContext context,
      {bool needsScaffold = false}) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: masterViewWidth),
      child: needsScaffold
          ? Scaffold(
              appBar: AppBar(
                title: widget.title,
                actions: widget.actionBuilder!(context, _ActionLevel.top),
                automaticallyImplyLeading: widget.automaticallyImplyLeading,
              ),
              body: widget.masterViewBuilder(context, true),
            )
          : widget.masterViewBuilder(context, true),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({
    required DetailPageBuilder builder,
    Object? arguments,
  })  : assert(builder != null),
        _builder = builder,
        _arguments = arguments;

  final DetailPageBuilder _builder;
  final Object? _arguments;

  @override
  Widget build(BuildContext context) {
    if (_arguments == null) {
      return Container();
    }
    final double screenHeight = MediaQuery.of(context).size.height;
    final double minHeight = (screenHeight - kToolbarHeight) / screenHeight;

    return DraggableScrollableSheet(
      initialChildSize: minHeight,
      minChildSize: minHeight,
      expand: false,
      builder: (BuildContext context, ScrollController controller) {
        return MouseRegion(
          // TODO(TonicArtos): Remove MouseRegion workaround for pointer hover events passing through DraggableScrollableSheet once https://github.com/flutter/flutter/issues/59741 is resolved.
          child: Card(
            color: Theme.of(context).cardColor,
            elevation: _kCardElevation,
            clipBehavior: Clip.antiAlias,
            margin: const EdgeInsets.fromLTRB(
                _kCardElevation, 0.0, _kCardElevation, 0.0),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(3.0)),
            ),
            child: _builder(
              context,
              _arguments,
              controller,
            ),
          ),
        );
      },
    );
  }
}
