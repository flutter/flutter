import 'package:flutter/material.dart';


class ExpansionPanelItem {
  final int panelIndex;
  final bool isHeader;

  const ExpansionPanelItem({required this.panelIndex, required this.isHeader});
}

/// SliverExpansion Panel List
class SliverExpansionPanelList extends StatelessWidget {
  final List<ExpansionPanel> expansionPanels;

  final List<ExpansionPanelItem> _panelItems = [];

  final ExpansionPanelCallback expansionCallback;

  SliverExpansionPanelList({
    super.key,
    required this.expansionPanels,
    required this.expansionCallback,
  });

  @override
  Widget build(BuildContext context) {
    /// Flatten the given ExpasionPanel into ExpansionPanelItem
    _updatePanels();

    /// Calculate the child count
    int childCount = _panelItems.length;

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final ExpansionPanelItem item = _panelItems[index];
        final ExpansionPanel currentPanel = expansionPanels[item.panelIndex];

        if (item.isHeader) {
          return _buildHeader(context, currentPanel, item.panelIndex);
        } else {
          return _buildBody(currentPanel);
        }
      }, childCount: childCount),
    );
  }

  void _updatePanels() {
    for (int i = 0; i < expansionPanels.length; i++) {
      final headerPanel = ExpansionPanelItem(panelIndex: i, isHeader: true);
      _panelItems.add(headerPanel);
      if (expansionPanels[i].isExpanded) {
        final bodyPanel = ExpansionPanelItem(panelIndex: i, isHeader: false);
        _panelItems.add(bodyPanel);
      }
    }
  }

  Widget _buildHeader(
      BuildContext context,
      ExpansionPanel panel,
      int panelIndex,
      ) {
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
          onPressed: (bool isExpanded) => _handlePressed(panel, panelIndex),
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
          onTap: () => _handlePressed(panel, panelIndex),
          child: header,
        ),
      );
    }

    return header;
  }

  void _handlePressed(ExpansionPanel panel, int panelIndex) {
    expansionCallback(panelIndex, !panel.isExpanded);
  }

  Widget _buildBody(ExpansionPanel panel) {
    return panel.body;
  }
}