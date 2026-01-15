import 'package:flutter/material.dart';

class ExpansionPanelItem {
  final int panelIndex;
  final bool isHeader;

  const ExpansionPanelItem({required this.panelIndex, required this.isHeader});
}

typedef RemovedItemBuilder<E> =
Widget Function(E item, BuildContext context, Animation<double> animation);

class ListModel<T> {
  ListModel({
    required this.listKey,
    required this.removedItemBuilder,
    required Iterable<T>? initialItems,
  }) : _items = List<T>.from(initialItems ?? <T>[]);

  final GlobalKey<SliverAnimatedListState> listKey;
  final RemovedItemBuilder<T> removedItemBuilder;
  final List<T> _items;

  SliverAnimatedListState get _animatedList => listKey.currentState!;

  void insert(int index, T item) {
    _items.insert(index, item);
    _animatedList.insertItem(index);
  }

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

  int get length => _items.length;

  T operator [](int index) => _items[index];

  int indexOf(T item) => _items.indexOf(item);
}

/// SliverExpansion Panel List
class SliverExpansionPanelList extends StatefulWidget {
  final List<ExpansionPanel> expansionPanels;
  final ExpansionPanelCallback expansionCallback;

  const SliverExpansionPanelList({
    super.key,
    required this.expansionPanels,
    required this.expansionCallback,
  });

  @override
  State<SliverExpansionPanelList> createState() =>
      _SliverExpansionPanelListState();
}

class _SliverExpansionPanelListState extends State<SliverExpansionPanelList> {
  final GlobalKey<SliverAnimatedListState> _listKey =
  GlobalKey<SliverAnimatedListState>();

  late ListModel<ExpansionPanelItem> _list;

  @override
  void initState() {
    super.initState();
    List<ExpansionPanelItem> items = _updatePanels();
    _list = ListModel(
      listKey: _listKey,
      removedItemBuilder: _buildRemovedItem,
      initialItems: items,
    );
  }

  @override
  void didUpdateWidget(covariant SliverExpansionPanelList oldWidget) {
    super.didUpdateWidget(oldWidget);
    List<ExpansionPanelItem> items = _updatePanels();
    // If counts don't match. Sync
    if(_list._items.length != items.length){
      _list = ListModel(
        listKey: _listKey,
        removedItemBuilder: _buildRemovedItem,
        initialItems: items,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverAnimatedList(
      key: _listKey,
      initialItemCount: _list.length,
      itemBuilder: (context, index, animation) {
        final ExpansionPanelItem item = _list._items[index];
        final ExpansionPanel currentPanel =
        widget.expansionPanels[item.panelIndex];

        if (item.isHeader) {
          return _buildHeader(context, index);
        } else {
          return SizeTransition(
            sizeFactor: animation,
            child: _buildBody(currentPanel),
          );
        }
      },
    );
  }

  List<ExpansionPanelItem> _updatePanels() {
    final result = <ExpansionPanelItem>[];
    for (int i = 0; i < widget.expansionPanels.length; i++) {
      final headerPanel = ExpansionPanelItem(panelIndex: i, isHeader: true);
      result.add(headerPanel);
      if (widget.expansionPanels[i].isExpanded) {
        final bodyPanel = ExpansionPanelItem(panelIndex: i, isHeader: false);
        result.add(bodyPanel);
      }
    }
    return result;
  }

  Widget _buildHeader(BuildContext context, int index) {
    final ExpansionPanelItem item = _list._items[index];
    final int panelIndex = item.panelIndex;
    final ExpansionPanel panel = widget.expansionPanels[panelIndex];

    final Widget headerWidget = panel.headerBuilder(context, panel.isExpanded);

    Widget expandIconPadded = Padding(
      padding: const EdgeInsetsDirectional.only(end: 8.0),
      child: IgnorePointer(
        ignoring: panel.canTapOnHeader,
        child: ExpandIcon(
          //color: widget.expandIconColor, //TODO: - Replace with widget's expandIconColor
          color: Colors.black,
          isExpanded: panel.isExpanded,
          padding: const EdgeInsets.all(12.0),
          //splashColor: child.splashColor, // TODO: - Replace with widget's splashColor
          splashColor: Theme.of(context).splashColor,
          //highlightColor: child.highlightColor, // TODO: - Replace with widget's highlightColor
          highlightColor: Theme.of(context).highlightColor,
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
            //duration: widget.animationDuration, // TODO: - Replace with animation duration
            duration: Duration(milliseconds: 200),
            curve: Curves.fastOutSlowIn,
            //margin: panel.isExpanded ? widget.expandedHeaderPadding : EdgeInsets.zero, // TODO: - Replace with expandedHeaderPadding
            margin: panel.isExpanded
                ? EdgeInsets.symmetric(
              vertical: 64.0 - kMinInteractiveDimension,
            )
                : EdgeInsets.zero,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                //minHeight: _kPanelHeaderCollapsedHeight,
                minHeight: kMinInteractiveDimension,
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

    return header;
  }

  void _handlePressed(int index) {
    final ExpansionPanelItem item = _list._items[index];
    final int panelIndex = item.panelIndex;
    final ExpansionPanel panel = widget.expansionPanels[panelIndex];

    /// TODO:- Update the internal _listModel
    if(panel.isExpanded){
      /// Must Remove at index + 1
      _list.removeAt(index + 1);
    } else {
      /// Must Add at index + 1
      ExpansionPanelItem itemToAdd = ExpansionPanelItem(panelIndex: panelIndex, isHeader: false);
      _list.insert(index + 1, itemToAdd);
    }

    widget.expansionCallback(panelIndex, !panel.isExpanded);
  }

  Widget _buildBody(ExpansionPanel panel) {
    return panel.body;
  }

  /// Build Removed Item
  Widget _buildRemovedItem(
      ExpansionPanelItem item,
      BuildContext context,
      Animation<double> animation,
      ) {
    return SizeTransition(
      sizeFactor: animation,
      child: widget.expansionPanels[item.panelIndex].body,
    );
  }
}
