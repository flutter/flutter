// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class BottomAppBarDemo extends StatefulWidget {
  static const String routeName = '/material/bottom_app_bar';

  @override
  State createState() => new _BottomAppBarDemoState();
}

// Flutter generally frowns upon abbrevation however this class uses two
// abbrevations extensively: "fab" for floating action button, and "bab"
// for bottom application bar.

class _BottomAppBarDemoState extends State<BottomAppBarDemo> {
  static final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  // FAB shape

  static const _ChoiceValue<Widget> kNoFab = const _ChoiceValue<Widget>(
    title: 'None',
    label: 'do not show a floating action button',
    value: null,
  );

  static const _ChoiceValue<Widget> kCircularFab = const _ChoiceValue<Widget>(
    title: 'Circular',
    label: 'circular floating action button',
    value: const FloatingActionButton(
      onPressed: _showSnackbar,
      child: const Icon(Icons.add),
      backgroundColor: Colors.orange,
    ),
  );

  static const _ChoiceValue<Widget> kDiamondFab = const _ChoiceValue<Widget>(
    title: 'Diamond',
    label: 'diamond shape floating action button',
    value: const _DiamondFab(
      onPressed: _showSnackbar,
      child: const Icon(Icons.add),
    ),
  );

  // Notch

  static const _ChoiceValue<bool> kShowNotchTrue = const _ChoiceValue<bool>(
    title: 'On',
    label: 'show bottom appbar notch',
    value: true,
  );

  static const _ChoiceValue<bool> kShowNotchFalse = const _ChoiceValue<bool>(
    title: 'Off',
    label: 'do not show bottom appbar notch',
    value: false,
  );

  // FAB Position

  static const _ChoiceValue<FloatingActionButtonLocation> kFabEndDocked = const _ChoiceValue<FloatingActionButtonLocation>(
    title: 'Attached - End',
    label: 'floating action button is docked at the end of the bottom app bar',
    value: FloatingActionButtonLocation.endDocked,
  );

  static const _ChoiceValue<FloatingActionButtonLocation> kFabCenterDocked = const _ChoiceValue<FloatingActionButtonLocation>(
    title: 'Attached - Center',
    label: 'floating action button is docked at the center of the bottom app bar',
    value: FloatingActionButtonLocation.centerDocked,
  );

  static const _ChoiceValue<FloatingActionButtonLocation> kFabEndFloat= const _ChoiceValue<FloatingActionButtonLocation>(
    title: 'Free - End',
    label: 'floating action button floats above the end of the bottom app bar',
    value: FloatingActionButtonLocation.endFloat,
  );

  static const _ChoiceValue<FloatingActionButtonLocation> kFabCenterFloat = const _ChoiceValue<FloatingActionButtonLocation>(
    title: 'Free - Center',
    label: 'floating action button is floats above the center of the bottom app bar',
    value: FloatingActionButtonLocation.centerFloat,
  );

  static void _showSnackbar() {
    const String text =
      "When the Scaffold's floating action button location changes, "
      'the floating action button animates to its new position.'
      'The BottomAppBar adapts its shape appropriately.';
    _scaffoldKey.currentState.showSnackBar(
      const SnackBar(content: const Text(text)),
    );
  }

  // App bar color

  static const List<Color> kBabColors = const <Color>[
    null,
    const Color(0xFFFFC100),
    const Color(0xFF91FAFF),
    const Color(0xFF00D1FF),
    const Color(0xFF00BCFF),
    const Color(0xFF009BEE),
  ];

  _ChoiceValue<Widget> _fabShape = kCircularFab;
  _ChoiceValue<bool> _showNotch = kShowNotchTrue;
  _ChoiceValue<FloatingActionButtonLocation> _fabLocation = kFabEndDocked;
  Color _babColor = kBabColors.first;

  void _onShowNotchChanged(_ChoiceValue<bool> value) {
    setState(() {
      _showNotch = value;
    });
  }

  void _onFabShapeChanged(_ChoiceValue<Widget> value) {
    setState(() {
      _fabShape = value;
    });
  }

  void _onFabLocationChanged(_ChoiceValue<FloatingActionButtonLocation> value) {
    setState(() {
      _fabLocation = value;
    });
  }

  void _onBabColorChanged(Color value) {
    setState(() {
      _babColor = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: const Text('Bottom app bar'),
        elevation: 0.0,
        actions: <Widget>[
          new IconButton(
            icon: const Icon(Icons.sentiment_very_satisfied),
            onPressed: () {
              setState(() {
                _fabShape = _fabShape == kCircularFab ? kDiamondFab : kCircularFab;
              });
            },
          ),
        ],
      ),
      body: new ListView(
        padding: const EdgeInsets.only(bottom: 88.0),
        children: <Widget>[
          const _Heading('FAB Shape'),

          new _RadioItem<Widget>(kCircularFab, _fabShape, _onFabShapeChanged),
          new _RadioItem<Widget>(kDiamondFab, _fabShape, _onFabShapeChanged),
          new _RadioItem<Widget>(kNoFab, _fabShape, _onFabShapeChanged),

          const Divider(),
          const _Heading('Notch'),

          new _RadioItem<bool>(kShowNotchTrue, _showNotch, _onShowNotchChanged),
          new _RadioItem<bool>(kShowNotchFalse, _showNotch, _onShowNotchChanged),

          const Divider(),
          const _Heading('FAB Position'),

          new _RadioItem<FloatingActionButtonLocation>(kFabEndDocked, _fabLocation, _onFabLocationChanged),
          new _RadioItem<FloatingActionButtonLocation>(kFabCenterDocked, _fabLocation, _onFabLocationChanged),
          new _RadioItem<FloatingActionButtonLocation>(kFabEndFloat, _fabLocation, _onFabLocationChanged),
          new _RadioItem<FloatingActionButtonLocation>(kFabCenterFloat, _fabLocation, _onFabLocationChanged),

          const Divider(),
          const _Heading('App bar color'),

          new _ColorsItem(kBabColors, _babColor, _onBabColorChanged),
        ],
      ),
      floatingActionButton: _fabShape.value,
      floatingActionButtonLocation: _fabLocation.value,
      bottomNavigationBar: new _DemoBottomAppBar(
        color: _babColor,
        fabLocation: _fabLocation.value,
        showNotch: _showNotch.value,
      ),
    );
  }
}

class _ChoiceValue<T> {
  const _ChoiceValue({ this.value, this.title, this.label });

  final T value;
  final String title;
  final String label; // For the Semantics widget that contains title

  @override
  String toString() => '$runtimeType("$title")';
}

class _RadioItem<T> extends StatelessWidget {
  const _RadioItem(this.value, this.groupValue, this.onChanged);

  final _ChoiceValue<T> value;
  final _ChoiceValue<T> groupValue;
  final ValueChanged<_ChoiceValue<T>> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return new Container(
      height: 56.0,
      padding: const EdgeInsetsDirectional.only(start: 16.0),
      alignment: AlignmentDirectional.centerStart,
      child: new MergeSemantics(
        child: new Row(
          children: <Widget>[
            new Radio<_ChoiceValue<T>>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
            ),
            new Expanded(
              child: new Semantics(
                container: true,
                button: true,
                label: value.label,
                child: new GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    onChanged(value);
                  },
                  child: new Text(
                    value.title,
                    style: theme.textTheme.subhead,
                  ),
                ),
              ),
            ),
          ]
        ),
      ),
    );
  }
}

class _ColorsItem extends StatelessWidget {
  const _ColorsItem(this.colors, this.selectedColor, this.onChanged);

  final List<Color> colors;
  final Color selectedColor;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    return new ExcludeSemantics(
      child: new Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: colors.map((Color color) {
          return new RawMaterialButton(
            onPressed: () {
              onChanged(color);
            },
            constraints: const BoxConstraints.tightFor(
              width: 32.0,
              height: 32.0,
            ),
            fillColor: color,
            shape: new CircleBorder(
              side: new BorderSide(
                color: color == selectedColor ? Colors.black : const Color(0xFFD5D7DA),
                width: 2.0,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return new Container(
      height: 48.0,
      padding: const EdgeInsetsDirectional.only(start: 56.0),
      alignment: AlignmentDirectional.centerStart,
      child: new Text(
        text,
        style: theme.textTheme.body1.copyWith(
          color: theme.primaryColor,
        ),
      ),
    );
  }
}

class _DemoBottomAppBar extends StatelessWidget {
  const _DemoBottomAppBar({ this.color, this.fabLocation, this.showNotch });

  final Color color;
  final FloatingActionButtonLocation fabLocation;
  final bool showNotch;

  static final List<FloatingActionButtonLocation> kCenterLocations = <FloatingActionButtonLocation>[
    FloatingActionButtonLocation.centerDocked,
    FloatingActionButtonLocation.centerFloat,
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> rowContents = <Widget> [
      new IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          showModalBottomSheet<Null>(
            context: context,
            builder: (BuildContext context) => const _DemoDrawer(),
          );
        },
      ),
    ];

    if (kCenterLocations.contains(fabLocation)) {
      rowContents.add(
        const Expanded(child: const SizedBox()),
      );
    }

    rowContents.addAll(<Widget> [
      new IconButton(
        icon: const Icon(Icons.search),
        onPressed: () {
          Scaffold.of(context).showSnackBar(
            const SnackBar(content: const Text('This is a dummy search action.')),
          );
        },
      ),
      new IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () {
          Scaffold.of(context).showSnackBar(
            const SnackBar(content: const Text('This is a dummy menu action.')),
          );
        },
      ),
    ]);

    return new BottomAppBar(
      color: color,
      hasNotch: showNotch,
      child: new Row(children: rowContents),
    );
  }
}

// A drawer that pops up from the bottom of the screen.
class _DemoDrawer extends StatelessWidget {
  const _DemoDrawer();

  @override
  Widget build(BuildContext context) {
    return new Drawer(
      child: new Column(
        children: const <Widget>[
          const ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Search'),
          ),
          const ListTile(
            leading: const Icon(Icons.threed_rotation),
            title: const Text('3D'),
          ),
        ],
      ),
    );
  }
}

// A diamond-shaped floating action button.
class _DiamondFab extends StatefulWidget {
  const _DiamondFab({
    this.child,
    this.notchMargin: 6.0,
    this.onPressed,
  });

  final Widget child;
  final double notchMargin;
  final VoidCallback onPressed;

  @override
  State createState() => new _DiamondFabState();
}

class _DiamondFabState extends State<_DiamondFab> {

  VoidCallback _clearComputeNotch;

  @override
  Widget build(BuildContext context) {
    return new Material(
      shape: const _DiamondBorder(),
      color: Colors.orange,
      child: new InkWell(
        onTap: widget.onPressed,
        child: new Container(
          width: 56.0,
          height: 56.0,
          child: IconTheme.merge(
            data: new IconThemeData(color: Theme.of(context).accentIconTheme.color),
            child: widget.child,
          ),
        ),
      ),
      elevation: 6.0,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _clearComputeNotch = Scaffold.setFloatingActionButtonNotchFor(context, _computeNotch);
  }

  @override
  void deactivate() {
    if (_clearComputeNotch != null)
      _clearComputeNotch();
    super.deactivate();
  }

  Path _computeNotch(Rect host, Rect guest, Offset start, Offset end) {
    final Rect marginedGuest = guest.inflate(widget.notchMargin);
    if (!host.overlaps(marginedGuest))
      return new Path()..lineTo(end.dx, end.dy);

    final Rect intersection = marginedGuest.intersect(host);
    // We are computing a "V" shaped notch, as in this diagram:
    //    -----\****   /-----
    //          \     /
    //           \   /
    //            \ /
    //
    //  "-" marks the top edge of the bottom app bar.
    //  "\" and "/" marks the notch outline
    //
    //  notchToCenter is the horizontal distance between the guest's center and
    //  the host's top edge where the notch starts (marked with "*").
    //  We compute notchToCenter by similar triangles:
    final double notchToCenter =
      intersection.height * (marginedGuest.height / 2.0)
      / (marginedGuest.width / 2.0);

    return new Path()
      ..lineTo(marginedGuest.center.dx - notchToCenter, host.top)
      ..lineTo(marginedGuest.left + marginedGuest.width / 2.0, marginedGuest.bottom)
      ..lineTo(marginedGuest.center.dx + notchToCenter, host.top)
      ..lineTo(end.dx, end.dy);
  }
}

class _DiamondBorder extends ShapeBorder {
  const _DiamondBorder();

  @override
  EdgeInsetsGeometry get dimensions {
    return const EdgeInsets.only();
  }

  @override
  Path getInnerPath(Rect rect, { TextDirection textDirection }) {
    return getOuterPath(rect, textDirection: textDirection);
  }

  @override
  Path getOuterPath(Rect rect, { TextDirection textDirection }) {
    return new Path()
      ..moveTo(rect.left + rect.width / 2.0, rect.top)
      ..lineTo(rect.right, rect.top + rect.height / 2.0)
      ..lineTo(rect.left + rect.width  / 2.0, rect.bottom)
      ..lineTo(rect.left, rect.top + rect.height / 2.0)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, { TextDirection textDirection }) {}

  // This border doesn't support scaling.
  @override
  ShapeBorder scale(double t) {
    return null;
  }
}
