import 'package:flutter/material.dart';
import 'breakpoint.dart';
import 'breakpoints.dart';
import 'slot.dart';
import 'slot_widget.dart';

const double materialCompactBreakpoint = 0;
const double materialMediumBreakpoint = 600;
const double materialExpandedBreakpoint = 840;

const double materialPadding = 8;

const double materialCompactMinGutter = 8;
const double materialMediumMinGutter = 8;
const double materialExpandedMinGutter = 8;

const String topPanelKey = 'topPanel';
const String bottomPanelKey = 'bottomPanel';
const String leftPanelKey = 'leftPanel';
const String rightPanelKey = 'rightPanel';
const String bodyKey = 'bodyPanel';

class AdaptiveLayout extends StatefulWidget {
  bool? useMaterial = false;

  bool? useCustom = false;

  List<NavigationDestination>? navDestinations;

  int? selectedIndex;

  List<Widget>? compactBody;

  List<Widget>? mediumBody;

  List<Widget>? expandedBody;

  List<Widget>? topWidgets;

  Slot? topPanel;

  Slot? bottomPanel;

  Slot? leftPanel;

  Slot? rightPanel;

  Slot? customBody;

  Color? backgroundColor;

  List<Breakpoint>? breakpoints = [
    CompactBreakpoint(),
    MediumBreakpoint(),
    ExpandedBreakpoint()
  ];

  AdaptiveLayout.material({
    Key? key,
    this.useCustom = false,
    this.useMaterial = true,
    this.backgroundColor,
    this.navDestinations,
    this.selectedIndex,
    this.topWidgets,
    this.compactBody,
    this.mediumBody,
    this.expandedBody,
    this.breakpoints,
  }) : super(key: key);

  AdaptiveLayout.custom({
    Key? key,
    this.useCustom = true,
    this.useMaterial = false,
    this.backgroundColor,
    this.topPanel,
    this.bottomPanel,
    this.rightPanel,
    this.leftPanel,
    this.customBody,
    this.breakpoints,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AdaptiveLayoutState();

  static Widget appBarBuilder({
    Widget? leading,
    double leadingWidth = 0,
    double height = 40,
    Widget? title,
    double elevation = 0,
    Color backgroundColor = Colors.transparent,
    NavigationRailLabelType labelType = NavigationRailLabelType.none,
    TextStyle? titleTextStyle,
  }) {
    return SizedBox(
      height: height,
      child: AppBar(
        elevation: elevation,
        leading: leading,
        leadingWidth: leadingWidth,
        title: title,
        backgroundColor: backgroundColor,
        titleTextStyle: titleTextStyle,
      ),
    );
  }

  static Widget navigationRailBuilder({
    required List<NavigationDestination> navDestinations,
    Widget? trailing,
    int selectedIndex = 0,
    double width = 72,
    bool extended = false,
    Color backgroundColor = Colors.transparent,
    IconThemeData selectedIconTheme = const IconThemeData(color: Colors.black),
    IconThemeData unselectedIconTheme =
        const IconThemeData(color: Colors.black),
    TextStyle selectedLabelTextStyle = const TextStyle(color: Colors.black),
  }) {
    return Builder(
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            width: (extended == true) ? 150 : width,
            child: NavigationRail(
              selectedIconTheme: selectedIconTheme,
              selectedLabelTextStyle: selectedLabelTextStyle,
              unselectedIconTheme: unselectedIconTheme,
              trailing: trailing,
              backgroundColor: backgroundColor,
              extended: extended,
              selectedIndex: selectedIndex,
              destinations: <NavigationRailDestination>[
                for (NavigationDestination destination in navDestinations)
                  NavigationRailDestination(
                    label: Text(destination.label),
                    icon: destination.icon,
                  )
              ],
            ),
          ),
        );
      },
    );
  }

  static BottomNavigationBar bottomNavigationBuilder({
    required List<NavigationDestination> navDestinations,
    int currentIndex = 0,
    double iconSize = 24,
    Color unselectedItemColor = Colors.black,
    Color backgroundColor = Colors.transparent,
    Color? selectedItemColor = Colors.black,
    BottomNavigationBarType type = BottomNavigationBarType.shifting,
  }) {
    List<BottomNavigationBarItem> bottomNavigationBarItems = [];
    for (NavigationDestination navigationDestination in navDestinations) {
      bottomNavigationBarItems.add(BottomNavigationBarItem(
          label: navigationDestination.label,
          icon: navigationDestination.icon));
    }
    return BottomNavigationBar(
        type: type,
        currentIndex: currentIndex,
        iconSize: iconSize,
        unselectedItemColor: unselectedItemColor,
        backgroundColor: backgroundColor,
        selectedItemColor: selectedItemColor,
        items: bottomNavigationBarItems);
  }
}

class _AdaptiveLayoutState extends State<AdaptiveLayout> {
  @override
  Widget build(BuildContext context) {
    if (widget.useMaterial == true) {
      Slot topPanel = Slot(
        breakpointWidgets: {
          CompactBreakpoint(): SlotWidget(
            key: const Key('AppBar1'),
            slotWidgets: widget.topWidgets,
          )
        },
      );
      Slot bottomPanel = Slot(
        breakpointWidgets: {
          CompactBreakpoint():
              SlotWidget(key: Key("BottomPanel1"), slotWidgets: [
            AdaptiveLayout.bottomNavigationBuilder(
              backgroundColor: const Color.fromRGBO(242, 231, 248, 1),
              navDestinations: widget.navDestinations!,
            )
          ]),
          MediumBreakpoint():
              SlotWidget(key: Key("BottomPanel2"), slotWidgets: const [
            SizedBox(
              width: 0,
              height: 0,
            )
          ]),
        },
      );
      Slot leftPanel = Slot(
        breakpointWidgets: {
          CompactBreakpoint():
              SlotWidget(key: Key("NavRail1"), slotWidgets: const [
            SizedBox(
              height: 0,
              width: 0,
            )
          ]),
          MediumBreakpoint(): SlotWidget(key: Key("NavRail2"), slotWidgets: [
            AdaptiveLayout.navigationRailBuilder(
                backgroundColor: const Color.fromRGBO(242, 231, 248, 1),
                navDestinations: widget.navDestinations!,
                extended: false)
          ]),
          ExpandedBreakpoint(): SlotWidget(key: Key("NavRail3"), slotWidgets: [
            AdaptiveLayout.navigationRailBuilder(
                backgroundColor: const Color.fromRGBO(242, 231, 248, 1),
                navDestinations: widget.navDestinations!,
                extended: true)
          ]),
        },
      );

      Map<Breakpoint, SlotWidget> breakpointWidgets2 = {};
      SlotWidget? compactBodySlot = (widget.compactBody != null)
          ? SlotWidget(
              key: const Key("BodyPanel1"),
              slotWidgets: widget.compactBody,
            )
          : null;
      if (compactBodySlot != null) {
        breakpointWidgets2.addAll({CompactBreakpoint(): compactBodySlot});
      }

      SlotWidget? mediumBodySlot = (widget.mediumBody != null)
          ? SlotWidget(
              key: const Key("BodyPanel2"),
              slotWidgets: widget.mediumBody,
            )
          : null;
      if (mediumBodySlot != null) {
        breakpointWidgets2.addAll({const MediumBreakpoint(): mediumBodySlot});
      }

      SlotWidget? expandedBodySlot = (widget.expandedBody != null)
          ? SlotWidget(
              key: const Key("BodyPanel3"),
              slotWidgets: widget.expandedBody,
            )
          : null;
      if (expandedBodySlot != null) {
        breakpointWidgets2
            .addAll({const ExpandedBreakpoint(): expandedBodySlot});
      }

      Slot bodyPanel = Slot(
        breakpointWidgets: breakpointWidgets2,
      );
      Slot rightPanel = Slot(
        breakpointWidgets: {
          CompactBreakpoint(): SlotWidget(),
        },
      );

      return AdaptiveLayout.custom(
        backgroundColor: widget.backgroundColor,
        topPanel: topPanel,
        bottomPanel: bottomPanel,
        leftPanel: leftPanel,
        customBody: bodyPanel,
        rightPanel: rightPanel,
      );
    } else {
      Map<String, Slot> totalSlots = {};
      List<Widget> totalWidgets = [];
      totalSlots.addAll({topPanelKey: widget.topPanel!});
      totalSlots.addAll({bottomPanelKey: widget.bottomPanel!});
      totalSlots.addAll({leftPanelKey: widget.leftPanel!});
      totalSlots.addAll({rightPanelKey: widget.rightPanel!});
      totalSlots.addAll({bodyKey: widget.customBody!});

      totalSlots.forEach(((key, value) {
        totalWidgets.add(LayoutId(id: key, child: value));
      }));

      return Container(
          color: widget.backgroundColor,
          child: CustomMultiChildLayout(
            delegate: _AdaptiveLayoutDelegate(
              totalSlots: totalSlots,
            ),
            children: totalWidgets,
          ));
    }
  }
}

class _AdaptiveLayoutDelegate extends MultiChildLayoutDelegate {
  final Map<String, Slot>? totalSlots;

  _AdaptiveLayoutDelegate({
    this.totalSlots,
  });

  @override
  void performLayout(Size size) {
    double top = 0;
    double bottom = 0;
    double left = 0;
    double right = 0;

    if (hasChild(leftPanelKey)) {
      Size panelSize = layoutChild(leftPanelKey, BoxConstraints.loose(size));
      positionChild(bottomPanelKey, Offset(left, top));
      left += panelSize.width;
    }

    if (hasChild(rightPanelKey)) {
      Size panelSize = layoutChild(rightPanelKey, BoxConstraints.loose(size));
      positionChild(rightPanelKey, Offset(size.width - panelSize.width, 0));
      right += panelSize.width;
    }

    if (hasChild(topPanelKey)) {
      Size panelSize = layoutChild(topPanelKey, BoxConstraints.loose(size));
      positionChild(topPanelKey, Offset.zero);
      top += panelSize.height;
    }

    if (hasChild(bottomPanelKey)) {
      Size panelSize = layoutChild(bottomPanelKey, BoxConstraints.loose(size));
      positionChild(bottomPanelKey, Offset(0, size.height - panelSize.height));
      bottom += panelSize.height;
    }

    final double bodyWidth = size.width - right - left;
    final double bodyHeight = size.height - bottom - top;

    if (hasChild(bodyKey)) {
      layoutChild(bodyKey, BoxConstraints.tight(Size(bodyWidth, bodyHeight)));
      positionChild(bodyKey, Offset(left, top));
    }
  }

  @override
  bool shouldRelayout(covariant _AdaptiveLayoutDelegate oldDelegate) {
    return oldDelegate.totalSlots != totalSlots;
  }
}
