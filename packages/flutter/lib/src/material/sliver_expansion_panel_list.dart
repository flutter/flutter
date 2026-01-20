import 'package:flutter/material.dart';

const double _kPanelHeaderCollapsedHeight = kMinInteractiveDimension;
const EdgeInsets _kPanelHeaderExpandedDefaultPadding = EdgeInsets.symmetric(
  vertical: 64.0 - _kPanelHeaderCollapsedHeight,
);
const EdgeInsets _kExpandIconPadding = EdgeInsets.all(12.0);

/// Signature for the callback that's called when an [SliverExpansionPanel] is
/// expanded or collapsed.
///
/// The position of the panel within an [SliverExpansionPanelList] is given by
/// [panelIndex].
typedef SliverExpansionPanelCallback = void Function(int panelIndex, bool isExpanded);

/// Signature for the callback that's called when the header of the
/// [SliverExpansionPanel] needs to rebuild.
typedef SliverExpansionPanelHeaderBuilder = Widget Function(BuildContext context, bool isExpanded);


/// A component used to construct a [SliverExpansionPanelList].
///
/// This widget is similar to [ExpansionPanel] but is specifically designed
/// for use with [SliverExpansionPanelList] to support sliver
/// animations and performance optimizations.
///
/// SliverExpansionPanels are only intended to use as children for [SliverExpansionPanelList]
///
/// It requires a unique [key] to correctly identify panels during the
/// diffing and animation process when the list is modified.
class SliverExpansionPanel {
  /// Creates an expansion panel to be used as a child for [SliverExpansionPanelList].
  ///
  /// The [key], [headerBuilder], and [body] arguments must not be null.
  /// See [SliverExpansionPanelList] for an example on how to use this widget.
  SliverExpansionPanel({
    required this.key,
    required this.headerBuilder,
    required this.body,
    this.isExpanded = false,
    this.canTapOnHeader = false,
    this.backgroundColor,
    this.splashColor,
    this.highlightColor,
  });

  /// The unique identifier for this panel.
  ///
  /// This key is **required** to maintain the identity of the panel when items
  /// are inserted, removed, or reordered in the [SliverExpansionPanelList].
  ///
  /// Unlike the standard [ExpansionPanelList], the sliver version uses a diffing
  /// algorithm to animate addition or removal of items. Without a stable key, [SliverExpansionPanelList]
  /// can lead to visual glitches or runtime errors (e.g. index out of range).
  ///
  /// **Do not** use a `GlobalKey` unless absolutely necessary, and avoid
  /// generating random keys (e.g., `Key(Random().toString())`) during build.
  /// Instead, use a [ValueKey] or [ObjectKey] derived from your data model.
  final Key key;

  /// The widget builder that builds the sliver expansion panels' header.
  final SliverExpansionPanelHeaderBuilder headerBuilder;

  /// The body of the sliver expansion panel that's displayed below the header.
  ///
  /// This widget is visible only when the panel is expanded.
  final Widget body;

  /// Whether the panel is expanded.
  ///
  /// Defaults to false.
  final bool isExpanded;

  /// Defines the splash color of the panel if [canTapOnHeader] is true,
  /// or the splash color of the expand/collapse IconButton if [canTapOnHeader]
  /// is false.
  ///
  /// If [canTapOnHeader] is false, and [ThemeData.useMaterial3] is
  /// true, this field will be ignored, as [IconButton.splashColor]
  /// will be ignored, and you should use [highlightColor] instead.
  ///
  /// If this is null, then the icon button will use its default splash color
  /// [ThemeData.splashColor], and the panel will use its default splash color
  /// [ThemeData.splashColor] (if [canTapOnHeader] is true).
  final Color? splashColor;

  /// Defines the highlight color of the panel if [canTapOnHeader] is true, or
  /// the highlight color of the expand/collapse IconButton if [canTapOnHeader]
  /// is false.
  ///
  /// If this is null, then the icon button will use its default highlight color
  /// [ThemeData.highlightColor], and the panel will use its default highlight
  /// color [ThemeData.highlightColor] (if [canTapOnHeader] is true).
  final Color? highlightColor;

  /// Whether tapping on the panel's header will expand/collapse it.
  ///
  /// Defaults to false.
  final bool canTapOnHeader;

  /// Defines the background color of the panel.
  ///
  /// Defaults to [ThemeData.cardColor].
  final Color? backgroundColor;
}

/// A data model representing a single item (either a header or a body)
/// within the flattened list of a [SliverExpansionPanelList].
///
/// Since [SliverExpansionPanelList] is built upon [SliverAnimatedList],
/// the hierarchical structure of "Panel -> [Header, Body]" must be
/// flattened into a linear list of items.
///
/// This class acts as the bridge between the user's [SliverExpansionPanel]
/// objects and the internal indices of the [SliverAnimatedList].
class SliverExpansionPanelItem {
  /// Creates an item for the flattened list.
  const SliverExpansionPanelItem({
    required this.panelIndex,
    required this.isHeader,
    required this.key,
  });

  /// The index of the original [SliverExpansionPanel] in the children list
  /// passed to [SliverExpansionPanelList].
  ///
  /// This index allows the builder to look up the correct [SliverExpansionPanel]
  /// data (like the header builder or body widget) from the source list.
  final int panelIndex;

  /// Whether this item represents the header of the panel.
  ///
  /// If true, this item renders the [SliverExpansionPanel.headerBuilder].
  /// If false, this item renders the [SliverExpansionPanel.body].
  final bool isHeader;

  /// The unique key derived from the [SliverExpansionPanel.key].
  ///
  /// This is used to maintain identity during the diffing process.
  /// This is the [SliverExpansionPanel.key] itself.
  final Key key;
}

/// Signature for a function that builds a widget to represent an item
/// that has been removed from a [ListModel].
///
/// This is used by [SliverAnimatedList] to animate the exit of an item
/// after it has already been removed from the underlying data source.
///
/// The [item] parameter provides the data that was at the index before removal,
/// allowing the "ghost" widget to be rendered correctly during its exit animation
typedef RemovedItemBuilder<E> =
Widget Function(E item, BuildContext context, Animation<double> animation);

/// A wrapper that synchronizes a standard [List] with a [SliverAnimatedListState].
///
/// Whenever the underlying data changes (via [insert]
/// or [removeAt]), the corresponding animation methods on the [SliverAnimatedList]
/// are called automatically.
///
/// This is a critical utility for [SliverExpansionPanelList] because it manages
/// the complex transition between "flattened" indices while keeping the
/// [SliverAnimatedList] in sync with the current UI state.
class ListModel<T> {
  /// Creates a [ListModel] that manages animations via the provided [listKey].
  ///
  /// The [removedItemBuilder] is used to generate the "ghost" widget that
  /// remains visible while an item is animating out of the list.
  ListModel({
    required this.listKey,
    required this.removedItemBuilder,
    required Iterable<T>? initialItems,
  }) : _items = List<T>.from(initialItems ?? <T>[]);

  /// The [GlobalKey] used to access the [SliverAnimatedListState].
  final GlobalKey<SliverAnimatedListState> listKey;

  /// The builder used to provide a widget for items that are being removed.
  final RemovedItemBuilder<T> removedItemBuilder;

  /// The internal data source.
  final List<T> _items;

  /// Helper to access the [SliverAnimatedListState] from the [listKey].
  SliverAnimatedListState get _animatedList => listKey.currentState!;

  /// Inserts an item into the list at the specified [index] and triggers
  /// the entrance animation in the [SliverAnimatedList].
  void insert(int index, T item) {
    _items.insert(index, item);
    _animatedList.insertItem(index);
  }

  /// Removes the item at [index] from the list and triggers the
  /// exit animation.
  ///
  /// Returns the removed item. The [removedItemBuilder] is used internally
  /// to build the widget that animates out.
  T removeAt(int index) {
    final T removedItem = _items.removeAt(index);
    if (removedItem != null) {
      _animatedList.removeItem(
        index,
            (BuildContext context, Animation<double> animation) =>
            removedItemBuilder(removedItem, context, animation),
      );
    }
    return removedItem;
  }

  /// The number of items currently in the model.
  int get length => _items.length;

  /// Returns the item at the given [index].
  T operator [](int index) => _items[index];

  /// Returns the first index of [item] in the list.
  int indexOf(T item) => _items.indexOf(item);
}

/// A clipper used to prevent shadow bleeding at the top of a body.
///
/// When a [SliverExpansionPanel] is expanded, the body is elevated. Without
/// clipping, the elevation shadow can "bleed" upwards onto the header above.
///
/// This clipper creates a bounding box that is strictly constrained at the top
/// (0.0), while allowing the shadow to spread freely on the left, right, and
/// bottom by providing a 10.0 pixel buffer. The shadow is
/// only visible below and to the sides of the body.
class _TopClosedClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(-10.0, 0.0, size.width + 10.0, size.height + 10.0);
  }

  @override
  bool shouldReclip(_TopClosedClipper oldClipper) => false;
}

/// A Material Design expansion panel list that integrates with sliver-based
/// scroll views.
///
/// This widget is a sliver-compatible version of [ExpansionPanelList]. It
/// allows for the efficient rendering of sliver expansion panels within a
/// [CustomScrollView]
///
/// The [SliverExpansionPanelList] manages its children's entry and exit
/// animations using an internal [SliverAnimatedList].
/// Expanding or collapsing panels smoothly pushes or pulls subsequent items
/// in the scroll sequence.
///
/// See also:
///
///  * [ExpansionPanelList], the non-sliver version of this widget.
///  * [SliverExpansionPanel], the data model used for children of this list.
///  * <https://material.io/archive/guidelines/components/expansion-panels.html>
class SliverExpansionPanelList extends StatefulWidget {
  /// Creates a [SliverExpansionPanelList].
  ///
  /// The [expansionPanels], [expansionCallback], [animationDuration],
  /// and [elevation] arguments must not be null.
  const SliverExpansionPanelList({
    super.key,
    required this.expansionPanels,
    required this.expansionCallback,
    this.animationDuration = kThemeAnimationDuration,
    this.expandedHeaderPadding = _kPanelHeaderExpandedDefaultPadding,
    this.expandIconColor,
    this.dividerColor,
    this.elevation = 2,
  });

  /// The expansion panels that constitute the list.
  final List<SliverExpansionPanel> expansionPanels;

  /// The callback that is fired when an expansion panel is expanded or collapsed.
  ///
  /// The arguments are the index of the panel and whether the panel is
  /// currently expanded.
  ///
  /// The callback should call [State.setState] when it is notified
  /// about the closing/opening panel.
  final SliverExpansionPanelCallback expansionCallback;

  /// The duration of the expansion animation.
  final Duration animationDuration;

  /// The padding that surrounds the panel header when expanded.
  ///
  /// By default, 16px of space is added to the header vertically (above and below)
  /// during expansion.
  final EdgeInsets expandedHeaderPadding;

  /// {@macro flutter.material.ExpandIcon.color}
  final Color? expandIconColor;

  /// Defines color for the divider when [ExpansionPanel.isExpanded] is false.
  ///
  /// If [dividerColor] is null, then [DividerThemeData.color] is used. If that
  /// is null, then [ThemeData.dividerColor] is used.
  final Color? dividerColor;

  /// Defines elevation for the [ExpansionPanel] while it's expanded.
  ///
  /// By default, the value of elevation is 2.
  final double elevation;

  @override
  State<SliverExpansionPanelList> createState() =>
      _SliverExpansionPanelListState();
}

class _SliverExpansionPanelListState extends State<SliverExpansionPanelList> {
  final GlobalKey<SliverAnimatedListState> _listKey =
  GlobalKey<SliverAnimatedListState>();

  late ListModel<SliverExpansionPanelItem> _list;

  @override
  void initState() {
    super.initState();
    assert(_allKeysUnique(), 'All SliverExpansionPanel keys values must be unique.');
    final List<SliverExpansionPanelItem> items = _flattenExpansionPanels();
    _list = ListModel(
      listKey: _listKey,
      removedItemBuilder: _buildRemovedItem,
      initialItems: items,
    );
  }

  @override
  void didUpdateWidget(covariant SliverExpansionPanelList oldWidget) {
    super.didUpdateWidget(oldWidget);

    // This block is only triggered when a [SliverExpansionPanel] is added to or
    // removed from the [expansionPanels] list.
    //
    // Expanding or collapsing an existing panel does not change the number of
    // [SliverExpansionPanel] objects in the list, so it will not trigger this logic.
    if (oldWidget.expansionPanels.length != widget.expansionPanels.length) {
      final List<SliverExpansionPanelItem> newItems = _flattenExpansionPanels();
      final List<SliverExpansionPanelItem> oldItems = _list._items;

      // Compare the length of items and decide whether an item has been added or removed
      final bool isItemRemoved = newItems.length < oldItems.length;

      if (isItemRemoved) {
        _removeItem(oldItems, newItems);
      } else {
        _addItem(newItems, oldItems);
      }
      // Sync data
      _list = ListModel(
        listKey: _listKey,
        removedItemBuilder: _buildRemovedItem,
        initialItems: newItems,
      );
    }
  }

  bool _allKeysUnique() {
    final identifierMap = <Object, bool>{};
    for (final SliverExpansionPanel child in widget.expansionPanels) {
      identifierMap[child.key] = true;
    }
    return identifierMap.length == widget.expansionPanels.length;
  }

  void _addItem(
      List<SliverExpansionPanelItem> newItems,
      List<SliverExpansionPanelItem> oldItems,
      ) {
    for (var i = 0; i < newItems.length; i++) {
      final Key currentKey = newItems[i].key;
      final Key? oldKey = oldItems.elementAtOrNull(i)?.key;

      if (oldKey == null || currentKey != oldKey) {
        final SliverExpansionPanelItem headerToAdd = newItems[i];
        final SliverExpansionPanelItem? bodyToAdd = newItems.elementAtOrNull(
          i + 1,
        );
        // Add Header
        _listKey.currentState?.insertItem(i);
        if (bodyToAdd != null &&
            (headerToAdd.panelIndex == bodyToAdd.panelIndex)) {
          // If the next panel has the same panel index, the panel is expanded.
          // Add the body as well.
          _listKey.currentState?.insertItem(i + 1);
        }
        break;
      }
    }
  }

  void _removeItem(
      List<SliverExpansionPanelItem> oldItems,
      List<SliverExpansionPanelItem> newItems,
      ) {
    for (var i = 0; i < oldItems.length; i++) {
      final Key? currentKey = newItems.elementAtOrNull(i)?.key;
      final Key oldKey = oldItems[i].key;

      if (currentKey == null || currentKey != oldKey) {
        final SliverExpansionPanelItem headerToRemove = _list._items[i];
        final SliverExpansionPanelItem? bodyToRemove = _list._items
            .elementAtOrNull(i + 1);

        // Remove the header
        _listKey.currentState?.removeItem(
          i,
              (BuildContext context, Animation<double> animation) =>
              const SizedBox.shrink(),
        );
        if ((bodyToRemove != null) &&
            (headerToRemove.panelIndex == bodyToRemove.panelIndex)) {
          // If the next panel has the same panel index, the panel is expanded.
          // Remove the body as well.
          _listKey.currentState?.removeItem(
            i,
                (BuildContext context, Animation<double> animation) =>
                const SizedBox.shrink(),
          );
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverAnimatedList(
      key: _listKey,
      initialItemCount: _list.length,
      itemBuilder: (context, index, animation) {
        final SliverExpansionPanelItem item = _list._items[index];
        final SliverExpansionPanel currentPanel =
        widget.expansionPanels[item.panelIndex];

        if (item.isHeader) {
          return _buildHeader(context, index);
        } else {
          return ClipRect(
            clipper: _TopClosedClipper(),
            child: PhysicalModel(
              color: Theme.of(context).cardColor,
              elevation: widget.elevation,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4.0)),
              clipBehavior: Clip.antiAlias,
              child: SizeTransition(
                sizeFactor: animation,
                child: _buildBody(currentPanel),
              ),
            ),
          );
        }
      },
    );
  }

  List<SliverExpansionPanelItem> _flattenExpansionPanels() {
    final result = <SliverExpansionPanelItem>[];
    for (var i = 0; i < widget.expansionPanels.length; i++) {
      final headerPanel = SliverExpansionPanelItem(
        panelIndex: i,
        isHeader: true,
        key: widget.expansionPanels[i].key,
      );
      result.add(headerPanel);

      if (widget.expansionPanels[i].isExpanded) {
        final bodyPanel = SliverExpansionPanelItem(
          panelIndex: i,
          isHeader: false,
          key: widget.expansionPanels[i].key,
        );
        result.add(bodyPanel);
      }
    }
    return result;
  }

  Widget _buildHeader(BuildContext context, int index) {
    final SliverExpansionPanelItem item = _list._items[index];
    final int panelIndex = item.panelIndex;
    final SliverExpansionPanel panel = widget.expansionPanels[panelIndex];

    final Widget headerWidget = panel.headerBuilder(context, panel.isExpanded);

    Widget expandIconPadded = Padding(
      padding: const EdgeInsetsDirectional.only(end: 8.0),
      child: IgnorePointer(
        ignoring: panel.canTapOnHeader,
        child: ExpandIcon(
          color: widget.expandIconColor,
          isExpanded: panel.isExpanded,
          padding: _kExpandIconPadding,
          splashColor: panel.splashColor,
          highlightColor: panel.highlightColor,
          onPressed: (bool isExpanded) => _handlePressed(index),
        ),
      ),
    );

    if (!panel.canTapOnHeader) {
      final MaterialLocalizations localizations = MaterialLocalizations.of(
        context,
      );
      expandIconPadded = Semantics(
        label: panel.isExpanded
            ? localizations.expandedIconTapHint
            : localizations.collapsedIconTapHint,
        container: true,
        child: expandIconPadded,
      );
    }

    Widget header = Row(
      children: <Widget>[
        Expanded(
          child: AnimatedContainer(
            duration: widget.animationDuration,
            curve: Curves.fastOutSlowIn,
            margin: panel.isExpanded
                ? widget.expandedHeaderPadding
                : EdgeInsets.zero,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: _kPanelHeaderCollapsedHeight,
              ),
              child: headerWidget,
            ),
          ),
        ),
        expandIconPadded,
      ],
    );

    if (panel.canTapOnHeader) {
      header = MergeSemantics(
        child: InkWell(
          splashColor: panel.splashColor,
          highlightColor: panel.highlightColor,
          onTap: () => _handlePressed(index),
          child: header,
        ),
      );
    }

    return Column(
      children: [
        header,
        AnimatedCrossFade(
          firstChild: Divider(height: 1, color: widget.dividerColor),
          secondChild: const SizedBox(height: 0),
          crossFadeState: panel.isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: widget.animationDuration,
        ),
      ],
    );
  }

  void _handlePressed(int index) {
    final SliverExpansionPanelItem item = _list._items[index];
    final int panelIndex = item.panelIndex;
    final SliverExpansionPanel panel = widget.expansionPanels[panelIndex];

    // Update the internal _listModel
    if (panel.isExpanded) {
      _list.removeAt(index + 1);
    } else {
      final itemToAdd = SliverExpansionPanelItem(
        key: widget.expansionPanels[panelIndex].key,
        panelIndex: panelIndex,
        isHeader: false,
      );
      _list.insert(index + 1, itemToAdd);
    }

    widget.expansionCallback(panelIndex, !panel.isExpanded);
  }

  Widget _buildBody(SliverExpansionPanel panel) {
    return panel.body;
  }

  Widget _buildRemovedItem(
      SliverExpansionPanelItem item,
      BuildContext context,
      Animation<double> animation,
      ) {
    return SizeTransition(
      sizeFactor: animation,
      child: widget.expansionPanels[item.panelIndex].body,
    );
  }
}
