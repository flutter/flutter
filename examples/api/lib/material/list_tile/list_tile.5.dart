// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Flutter code sample for [ListTile].

void main() => runApp(const ListTileApp());

class ListTileApp extends StatefulWidget {
  const ListTileApp({super.key});

  @override
  State<ListTileApp> createState() => _ListTileAppState();
}

class _ListTileAppState extends State<ListTileApp> {
  bool useMaterial3 = true;
  bool isDark = false;
  bool useAdaptiveVisualDensity = false;
  bool showDividers = false;
  bool isLtr = true;

  void onToggleUseMaterial3(bool newUseMaterial3) {
    if (newUseMaterial3 != useMaterial3) {
      setState(() {
        useMaterial3 = newUseMaterial3;
      });
    }
  }

  void onToggleThemeMode(bool newIsDark) {
    if (newIsDark != isDark) {
      setState(() {
        isDark = newIsDark;
      });
    }
  }

  void onToggleVisualDensity(bool newUseAdaptiveVisualDensity) {
    if (newUseAdaptiveVisualDensity != useAdaptiveVisualDensity) {
      setState(() {
        useAdaptiveVisualDensity = newUseAdaptiveVisualDensity;
      });
    }
  }

  void onToggleShowDividers(bool newShowDividers) {
    if (newShowDividers != showDividers) {
      setState(() {
        showDividers = newShowDividers;
      });
    }
  }

  void onToggleIsLtr(bool newIsLtr) {
    if (newIsLtr != isLtr) {
      setState(() {
        isLtr = newIsLtr;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: useMaterial3,
        visualDensity: useAdaptiveVisualDensity
            ? VisualDensity.adaptivePlatformDensity
            : VisualDensity.standard,
        colorSchemeSeed: Colors.orange,
      ),
      darkTheme: ThemeData(
        useMaterial3: useMaterial3,
        visualDensity: useAdaptiveVisualDensity
            ? VisualDensity.adaptivePlatformDensity
            : VisualDensity.standard,
        colorSchemeSeed: Colors.orange,
        brightness: Brightness.dark,
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: Directionality(
        textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
        child: ListTileExample(
          useMaterial3: useMaterial3,
          onToggleUseMaterial3: onToggleUseMaterial3,
          isDark: isDark,
          onToggleThemeMode: onToggleThemeMode,
          useAdaptiveVisualDensity: useAdaptiveVisualDensity,
          onToggleVisualDensity: onToggleVisualDensity,
          showDividers: showDividers,
          onToggleShowDividers: onToggleShowDividers,
          isLtr: isLtr,
          onToggleIsLtr: onToggleIsLtr,
        ),
      ),
    );
  }
}

double listWidth = 360.0;
double cardWidth = listWidth;

Text headline = const Text('Headline');
Text supportingText = const Text('Supporting text');
String longSupportingText =
    'Supporting text that is long enough to fill up multiple lines';
Text overline = const Text('Overline');
Text trailingSupportingText = const Text('100+');
CircleAvatar avatar = const CircleAvatar(child: Text('A'));
Icon leadingIcon = const Icon(Icons.person_outline);
Icon trailingIcon = const Icon(Icons.arrow_right);
final Checkbox trailingCheckbox =
    Checkbox(value: true, onChanged: (bool? _) {});
ImagePlaceholder leadingImage = const ImagePlaceholder(height: 56, width: 56);
ImagePlaceholder leadingVideo = const ImagePlaceholder(height: 64, width: 114);

class ListTileExample extends StatelessWidget {
  const ListTileExample({
    super.key,
    required this.useMaterial3,
    required this.onToggleUseMaterial3,
    required this.isDark,
    required this.onToggleThemeMode,
    required this.useAdaptiveVisualDensity,
    required this.onToggleVisualDensity,
    required this.showDividers,
    required this.onToggleShowDividers,
    required this.isLtr,
    required this.onToggleIsLtr,
  });

  final bool useMaterial3;
  final void Function(bool useMaterial3) onToggleUseMaterial3;

  final bool isDark;
  final void Function(bool isDark) onToggleThemeMode;

  final bool useAdaptiveVisualDensity;
  final void Function(bool useAdaptiveVisualDensity) onToggleVisualDensity;

  final bool showDividers;
  final void Function(bool showDividers) onToggleShowDividers;

  final bool isLtr;
  final void Function(bool newIsLtr) onToggleIsLtr;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ListTile Material ${useMaterial3 ? '3' : '2'} Samples'),
        actions: <Widget>[menu()],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              children: <Widget>[
                OneLineLists(showDividers: showDividers),
                const SizedBox(height: 16),
                TwoLineListTiles(showDividers: showDividers),
                const SizedBox(height: 16),
                TwoLineOverlineListTiles(showDividers: showDividers),
                const SizedBox(height: 16),
                ThreeLineListTiles(showDividers: showDividers),
                const SizedBox(height: 16),
                ThreeLineOverlineListTiles(showDividers: showDividers),
                const SizedBox(height: 16),
                CheckboxListTiles(showDividers: showDividers),
                const SizedBox(height: 16),
                RadioListTiles(showDividers: showDividers),
                const SizedBox(height: 16),
                SwitchListTiles(showDividers: showDividers),
                const SizedBox(height: 16),
                ExpansionTiles(showDividers: showDividers),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget menu() {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.more_vert),
      onSelected: (int value) {
        switch (value) {
          case 0:
            onToggleUseMaterial3(!useMaterial3);
          case 1:
            onToggleThemeMode(!isDark);
          case 2:
            onToggleVisualDensity(!useAdaptiveVisualDensity);
          case 3:
            onToggleShowDividers(!showDividers);
          case 4:
            onToggleIsLtr(!isLtr);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
        CheckedPopupMenuItem<int>(
          value: 0,
          checked: useMaterial3,
          child: const Text('Use Material 3'),
        ),
        CheckedPopupMenuItem<int>(
          value: 1,
          checked: isDark,
          child: const Text('Use dark mode'),
        ),
        CheckedPopupMenuItem<int>(
          value: 2,
          checked: useAdaptiveVisualDensity,
          child: const Text('Use adaptive platform density'),
        ),
        CheckedPopupMenuItem<int>(
          value: 3,
          checked: showDividers,
          child: const Text('Show dividers'),
        ),
        CheckedPopupMenuItem<int>(
          value: 4,
          checked: isLtr,
          child: const Text('Left-to-right text'),
        ),
      ],
    );
  }
}

class OneLineLists extends StatelessWidget {
  const OneLineLists({super.key, required this.showDividers});

  final bool showDividers;

  @override
  Widget build(BuildContext context) {
    return ListCard(
      titleText: 'One-line ListTiles',
      showDividers: showDividers,
      children: <Widget>[
        ListTile(
          title: headline,
          onTap: () {},
        ),
        ListTile(
          title: headline,
          leading: leadingIcon,
          onTap: () {},
        ),
        ListTile(
          title: headline,
          leading: avatar,
          trailing: trailingCheckbox,
          trailingConstraint:
              ListTileConstraint.icon24,
          onTap: () {},
        ),
        ListTile(
          title: headline,
          leading: leadingImage,
          leadingConstraint: ListTileConstraint.image,
          trailing: trailingSupportingText,
          onTap: () {},
        ),
        ListTile(
          title: headline,
          leading: leadingVideo,
          leadingConstraint: ListTileConstraint.video,
          trailing: trailingIcon,
          onTap: () {},
        ),
        ListTile(
          title: headline,
          leading: leadingVideo,
          leadingConstraint: ListTileConstraint.video,
          trailing: const Text('10 Episodes'),
          onTap: () {},
        ),
      ],
    );
  }
}

class TwoLineListTiles extends StatelessWidget {
  const TwoLineListTiles({super.key, required this.showDividers});

  final bool showDividers;

  @override
  Widget build(BuildContext context) {
    return ListCard(
      titleText: 'Two-line ListTiles',
      showDividers: showDividers,
      children: <Widget>[
        ListTile(
          title: headline,
          subtitle: supportingText,
          onTap: () {},
        ),
        ListTile(
          title: headline,
          subtitle: Text(
            longSupportingText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {},
        ),
        ListTile(
          title: headline,
          subtitle: supportingText,
          leading: leadingIcon,
          onTap: () {},
        ),
        ListTile(
          title: headline,
          subtitle: supportingText,
          leading: avatar,
          trailing: trailingCheckbox,
          trailingConstraint:
              ListTileConstraint.icon24,
          onTap: () {},
        ),
        ListTile(
          title: headline,
          subtitle: supportingText,
          leading: leadingImage,
          leadingConstraint: ListTileConstraint.image,
          trailing: trailingSupportingText,
          onTap: () {},
        ),
        ListTile(
          title: headline,
          subtitle: Text(
            longSupportingText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          leadingConstraint: ListTileConstraint.image,
          trailing: trailingSupportingText,
          onTap: () {},
        ),
        ListTile(
          title: headline,
          subtitle: supportingText,
          leading: leadingVideo,
          trailing: IconButton(onPressed: () {}, icon: trailingIcon),
          leadingConstraint: ListTileConstraint.video,
          trailingConstraint:
              ListTileConstraint.icon24,
          onTap: () {},
        ),
        ListTile(
          title: headline,
          subtitle: supportingText,
          leading: leadingVideo,
          leadingConstraint: ListTileConstraint.video,
          trailing: trailingIcon,
          onTap: () {},
        ),
      ],
    );
  }
}

class TwoLineOverlineListTiles extends StatelessWidget {
  const TwoLineOverlineListTiles({super.key, required this.showDividers});

  final bool showDividers;

  @override
  Widget build(BuildContext context) {
    return ListCard(
      showDividers: showDividers,
      titleText: 'Two-line Overline ListTiles',
      children: <Widget>[
        ListTile(
          title: headline,
          overline: supportingText,
          onTap: () {},
        ),
        ListTile(
          title: headline,
          overline: Text(
            longSupportingText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {},
        ),
        ListTile(
          title: headline,
          overline: supportingText,
          leading: leadingIcon,
          onTap: () {},
        ),
        ListTile(
          title: headline,
          overline: supportingText,
          leading: avatar,
          trailing: trailingCheckbox,
          trailingConstraint:
              ListTileConstraint.icon24,
          onTap: () {},
        ),
        ListTile(
          title: headline,
          overline: supportingText,
          leading: leadingImage,
          leadingConstraint: ListTileConstraint.image,
          trailing: trailingSupportingText,
          onTap: () {},
        ),
        ListTile(
          title: headline,
          overline: Text(
            longSupportingText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          leading: leadingImage,
          leadingConstraint: ListTileConstraint.image,
          trailing: trailingSupportingText,
          onTap: () {},
        ),
        ListTile(
          title: headline,
          overline: supportingText,
          leading: leadingVideo,
          leadingConstraint: ListTileConstraint.video,
          trailing: trailingIcon,
          onTap: () {},
        ),
      ],
    );
  }
}

class ThreeLineListTiles extends StatelessWidget {
  const ThreeLineListTiles({super.key, required this.showDividers});

  final bool showDividers;

  @override
  Widget build(BuildContext context) {
    return ListCard(
      titleText: 'Three-line ListTiles',
      showDividers: showDividers,
      children: <Widget>[
        ListTile(
          title: headline,
          isThreeLine: true,
          subtitle: Text(
            longSupportingText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {},
        ),
        ListTile(
          title: headline,
          isThreeLine: true,
          subtitle: Text(
            longSupportingText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          leading: leadingIcon,
          onTap: () {},
        ),
        ListTile(
          title: headline,
          isThreeLine: true,
          subtitle: Text(
            longSupportingText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          leading: avatar,
          trailing: trailingCheckbox,
          trailingConstraint:
              ListTileConstraint.icon24,
          onTap: () {},
        ),
        ListTile(
          title: headline,
          isThreeLine: true,
          titleAlignment: ListTileTitleAlignment.threeLine,
          subtitle: Text(
            longSupportingText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          leading: leadingImage,
          leadingConstraint: ListTileConstraint.image,
          trailing: trailingSupportingText,
          onTap: () {},
        ),
        ListTile(
          title: headline,
          isThreeLine: true,
          subtitle: Text(
            longSupportingText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          leading: leadingVideo,
          leadingConstraint: ListTileConstraint.video,
          trailing: trailingIcon,
          onTap: () {},
        ),
        ListTile(
          title: headline,
          isThreeLine: true,
          titleAlignment: ListTileTitleAlignment.threeLine,
          subtitle: Text(
            longSupportingText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          leading: leadingVideo,
          trailing: IconButton(onPressed: () {}, icon: trailingIcon),
          leadingConstraint: ListTileConstraint.video,
          trailingConstraint:
              ListTileConstraint.icon24,
          onTap: () {},
        ),
      ],
    );
  }
}

class ThreeLineOverlineListTiles extends StatelessWidget {
  const ThreeLineOverlineListTiles({super.key, required this.showDividers});

  final bool showDividers;

  @override
  Widget build(BuildContext context) {
    return ListCard(
      titleText: 'Three-line Overline ListTiles',
      showDividers: showDividers,
      children: <Widget>[
        ListTile(
          title: headline,
          isThreeLine: true,
          overline: supportingText,
          subtitle: Text(
            longSupportingText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {},
        ),
        ListTile(
          title: headline,
          isThreeLine: true,
          overline: supportingText,
          subtitle: Text(
            longSupportingText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          leading: leadingIcon,
          onTap: () {},
        ),
        ListTile(
          title: headline,
          isThreeLine: true,
          overline: supportingText,
          subtitle: Text(
            longSupportingText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          leading: avatar,
          trailing: trailingCheckbox,
          trailingConstraint:
              ListTileConstraint.icon24,
          onTap: () {},
        ),
        ListTile(
          title: headline,
          isThreeLine: true,
          overline: supportingText,
          subtitle: Text(
            longSupportingText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          leading: leadingImage,
          leadingConstraint: ListTileConstraint.image,
          trailing: trailingSupportingText,
          onTap: () {},
        ),
        ListTile(
          title: headline,
          isThreeLine: true,
          overline: supportingText,
          subtitle: Text(
            longSupportingText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          leading: leadingVideo,
          leadingConstraint: ListTileConstraint.video,
          trailing: trailingIcon,
          onTap: () {},
        ),
        ListTile(
          title: headline,
          isThreeLine: true,
          overline: supportingText,
          subtitle: Text(
            longSupportingText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          leading: leadingVideo,
          trailing: IconButton(onPressed: () {}, icon: trailingIcon),
          leadingConstraint: ListTileConstraint.video,
          trailingConstraint:
              ListTileConstraint.icon24,
          onTap: () {},
        ),
      ],
    );
  }
}

class CheckboxListTiles extends StatefulWidget {
  const CheckboxListTiles({super.key, required this.showDividers});

  final bool showDividers;

  @override
  State<CheckboxListTiles> createState() => _CheckboxListTilesState();
}

class _CheckboxListTilesState extends State<CheckboxListTiles> {
  bool leadingControlAffinity = false;

  void _onAffinityChanged(bool value) {
    setState(() {
      leadingControlAffinity = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListCard(
      titleText: 'Checkbox List Tiles',
      showDividers: widget.showDividers,
      controls: <Widget>[
        SwitchListTile(
          value: leadingControlAffinity,
          onChanged: _onAffinityChanged,
          title: const Text('Leading control affinity'),
        )
      ],
      children: <Widget>[
        ToggleBooleanState(
          builder: (bool value, void Function(bool value) onChanged) =>
              CheckboxListTile(
            value: value,
            onChanged: (bool? b) => onChanged(b ?? false),
            controlAffinity: leadingControlAffinity
                ? ListTileControlAffinity.leading
                : ListTileControlAffinity.trailing,
          ),
        ),
        ToggleBooleanState(
          builder: (bool value, void Function(bool value) onChanged) =>
              CheckboxListTile(
            value: value,
            onChanged: (bool? b) => onChanged(b ?? false),
            title: headline,
            controlAffinity: leadingControlAffinity
                ? ListTileControlAffinity.leading
                : ListTileControlAffinity.trailing,
          ),
        ),
        ToggleBooleanState(
          builder: (bool value, void Function(bool value) onChanged) =>
              CheckboxListTile(
            value: value,
            onChanged: (bool? b) => onChanged(b ?? false),
            title: headline,
            secondary: leadingIcon,
            controlAffinity: leadingControlAffinity
                ? ListTileControlAffinity.leading
                : ListTileControlAffinity.trailing,
          ),
        ),
        ToggleBooleanState(
          builder: (bool value, void Function(bool value) onChanged) =>
              CheckboxListTile(
            value: value,
            onChanged: (bool? b) => onChanged(b ?? false),
            title: headline,
            secondary: avatar,
            controlAffinity: leadingControlAffinity
                ? ListTileControlAffinity.leading
                : ListTileControlAffinity.trailing,
          ),
        ),
        ToggleBooleanState(
          builder: (bool value, void Function(bool value) onChanged) =>
              CheckboxListTile(
            value: value,
            onChanged: (bool? b) => onChanged(b ?? false),
            title: headline,
            secondary: leadingImage,
            secondaryConstraint: ListTileConstraint.image,
            controlAffinity: leadingControlAffinity
                ? ListTileControlAffinity.leading
                : ListTileControlAffinity.trailing,
          ),
        ),
        ToggleBooleanState(
          builder: (bool value, void Function(bool value) onChanged) =>
              CheckboxListTile(
            value: value,
            onChanged: (bool? b) => onChanged(b ?? false),
            title: headline,
            secondary: leadingVideo,
            secondaryConstraint: ListTileConstraint.video,
            controlAffinity: leadingControlAffinity
                ? ListTileControlAffinity.leading
                : ListTileControlAffinity.trailing,
          ),
        ),
        ToggleBooleanState(
          builder: (bool value, void Function(bool value) onChanged) =>
              CheckboxListTile(
            value: value,
            onChanged: (bool? b) => onChanged(b ?? false),
            title: headline,
            subtitle: supportingText,
            controlAffinity: leadingControlAffinity
                ? ListTileControlAffinity.leading
                : ListTileControlAffinity.trailing,
          ),
        ),
        ToggleBooleanState(
          builder: (bool value, void Function(bool value) onChanged) =>
              CheckboxListTile(
            value: value,
            onChanged: (bool? b) => onChanged(b ?? false),
            title: headline,
            overline: supportingText,
            controlAffinity: leadingControlAffinity
                ? ListTileControlAffinity.leading
                : ListTileControlAffinity.trailing,
          ),
        ),
        ToggleBooleanState(
          builder: (bool value, void Function(bool value) onChanged) =>
              CheckboxListTile(
            value: value,
            onChanged: (bool? b) => onChanged(b ?? false),
            isThreeLine: true,
            title: headline,
            subtitle: supportingText,
            overline: supportingText,
            controlAffinity: leadingControlAffinity
                ? ListTileControlAffinity.leading
                : ListTileControlAffinity.trailing,
          ),
        ),
      ],
    );
  }
}

class RadioListTiles extends StatefulWidget {
  const RadioListTiles({super.key, required this.showDividers});

  final bool showDividers;

  @override
  State<RadioListTiles> createState() => _RadioListTilesState();
}

class _RadioListTilesState extends State<RadioListTiles> {
  int selectedValue = 1;
  bool leadingControlAffinity = true;

  void _onSelectedChanged(int? i) {
    setState(() {
      selectedValue = i ?? 1;
    });
  }

  void _onAffinityChanged(bool value) {
    setState(() {
      leadingControlAffinity = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListCard(
      titleText: 'Radio List Tiles',
      showDividers: widget.showDividers,
      controls: <Widget>[
        SwitchListTile(
          value: leadingControlAffinity,
          onChanged: _onAffinityChanged,
          title: const Text('Leading control affinity'),
        ),
      ],
      children: <Widget>[
        RadioListTile<int>(
          value: 1,
          groupValue: selectedValue,
          onChanged: _onSelectedChanged,
          controlAffinity: leadingControlAffinity
              ? ListTileControlAffinity.leading
              : ListTileControlAffinity.trailing,
        ),
        RadioListTile<int>(
          value: 2,
          groupValue: selectedValue,
          onChanged: _onSelectedChanged,
          title: headline,
          controlAffinity: leadingControlAffinity
              ? ListTileControlAffinity.leading
              : ListTileControlAffinity.trailing,
        ),
        RadioListTile<int>(
          value: 3,
          groupValue: selectedValue,
          onChanged: _onSelectedChanged,
          title: headline,
          secondary: leadingIcon,
          controlAffinity: leadingControlAffinity
              ? ListTileControlAffinity.leading
              : ListTileControlAffinity.trailing,
        ),
        RadioListTile<int>(
          value: 4,
          groupValue: selectedValue,
          onChanged: _onSelectedChanged,
          title: headline,
          subtitle: supportingText,
          controlAffinity: leadingControlAffinity
              ? ListTileControlAffinity.leading
              : ListTileControlAffinity.trailing,
        ),
        RadioListTile<int>(
          value: 5,
          groupValue: selectedValue,
          onChanged: _onSelectedChanged,
          title: headline,
          overline: supportingText,
          controlAffinity: leadingControlAffinity
              ? ListTileControlAffinity.leading
              : ListTileControlAffinity.trailing,
        ),
        RadioListTile<int>(
          value: 6,
          groupValue: selectedValue,
          onChanged: _onSelectedChanged,
          title: headline,
          subtitle: supportingText,
          secondary: leadingImage,
          secondaryConstraint: ListTileConstraint.image,
          controlAffinity: leadingControlAffinity
              ? ListTileControlAffinity.leading
              : ListTileControlAffinity.trailing,
        ),
        RadioListTile<int>(
          value: 7,
          groupValue: selectedValue,
          onChanged: _onSelectedChanged,
          title: headline,
          subtitle: supportingText,
          secondary: leadingVideo,
          secondaryConstraint: ListTileConstraint.video,
          controlAffinity: leadingControlAffinity
              ? ListTileControlAffinity.leading
              : ListTileControlAffinity.trailing,
        ),
        RadioListTile<int>(
          value: 8,
          groupValue: selectedValue,
          onChanged: _onSelectedChanged,
          isThreeLine: true,
          title: headline,
          subtitle: supportingText,
          overline: supportingText,
          controlAffinity: leadingControlAffinity
              ? ListTileControlAffinity.leading
              : ListTileControlAffinity.trailing,
        ),
      ],
    );
  }
}

class SwitchListTiles extends StatefulWidget {
  const SwitchListTiles({super.key, required this.showDividers});

  final bool showDividers;

  @override
  State<SwitchListTiles> createState() => _SwitchListTilesState();
}

class _SwitchListTilesState extends State<SwitchListTiles> {
  bool leadingControlAffinity = false;

  void _onAffinityChanged(bool value) {
    setState(() {
      leadingControlAffinity = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListCard(
      titleText: 'Switch List Tiles',
      showDividers: widget.showDividers,
      controls: <Widget>[
        SwitchListTile(
          value: leadingControlAffinity,
          onChanged: _onAffinityChanged,
          title: const Text('Leading control affinity'),
        ),
      ],
      children: <Widget>[
        ToggleBooleanState(
          builder: (bool value, void Function(bool value) onChanged) =>
              SwitchListTile(
            value: value,
            onChanged: onChanged,
            controlAffinity: leadingControlAffinity
                ? ListTileControlAffinity.leading
                : ListTileControlAffinity.trailing,
          ),
        ),
        ToggleBooleanState(
          builder: (bool value, void Function(bool value) onChanged) =>
              SwitchListTile(
            value: value,
            onChanged: onChanged,
            title: headline,
            controlAffinity: leadingControlAffinity
                ? ListTileControlAffinity.leading
                : ListTileControlAffinity.trailing,
          ),
        ),
        ToggleBooleanState(
          builder: (bool value, void Function(bool value) onChanged) =>
              SwitchListTile(
            value: value,
            onChanged: onChanged,
            title: headline,
            secondary: leadingIcon,
            controlAffinity: leadingControlAffinity
                ? ListTileControlAffinity.leading
                : ListTileControlAffinity.trailing,
          ),
        ),
        ToggleBooleanState(
          builder: (bool value, void Function(bool value) onChanged) =>
              SwitchListTile(
            value: value,
            onChanged: onChanged,
            title: headline,
            subtitle: supportingText,
            controlAffinity: leadingControlAffinity
                ? ListTileControlAffinity.leading
                : ListTileControlAffinity.trailing,
          ),
        ),
        ToggleBooleanState(
          builder: (bool value, void Function(bool value) onChanged) =>
              SwitchListTile(
            value: value,
            onChanged: onChanged,
            title: headline,
            subtitle: supportingText,
            secondary: avatar,
            controlAffinity: leadingControlAffinity
                ? ListTileControlAffinity.leading
                : ListTileControlAffinity.trailing,
          ),
        ),
        ToggleBooleanState(
          builder: (bool value, void Function(bool value) onChanged) =>
              SwitchListTile(
            value: value,
            onChanged: onChanged,
            title: headline,
            subtitle: supportingText,
            secondary: leadingImage,
            secondaryConstraint: ListTileConstraint.image,
            controlAffinity: leadingControlAffinity
                ? ListTileControlAffinity.leading
                : ListTileControlAffinity.trailing,
          ),
        ),
        ToggleBooleanState(
          builder: (bool value, void Function(bool value) onChanged) =>
              SwitchListTile(
            value: value,
            onChanged: onChanged,
            title: headline,
            subtitle: supportingText,
            secondary: leadingVideo,
            secondaryConstraint: ListTileConstraint.video,
            controlAffinity: leadingControlAffinity
                ? ListTileControlAffinity.leading
                : ListTileControlAffinity.trailing,
          ),
        ),
        ToggleBooleanState(
          builder: (bool value, void Function(bool value) onChanged) =>
              SwitchListTile(
            value: value,
            onChanged: onChanged,
            title: headline,
            overline: supportingText,
            controlAffinity: leadingControlAffinity
                ? ListTileControlAffinity.leading
                : ListTileControlAffinity.trailing,
          ),
        ),
        ToggleBooleanState(
          builder: (bool value, void Function(bool value) onChanged) =>
              SwitchListTile(
            value: value,
            onChanged: onChanged,
            isThreeLine: true,
            title: headline,
            subtitle: supportingText,
            overline: supportingText,
            controlAffinity: leadingControlAffinity
                ? ListTileControlAffinity.leading
                : ListTileControlAffinity.trailing,
          ),
        ),
        ToggleBooleanState(
          builder: (bool value, void Function(bool value) onChanged) =>
              SwitchListTile(
            value: value,
            onChanged: onChanged,
            isThreeLine: true,
            title: headline,
            subtitle: supportingText,
            secondary: leadingIcon,
            controlAffinity: leadingControlAffinity
                ? ListTileControlAffinity.leading
                : ListTileControlAffinity.trailing,
          ),
        ),
      ],
    );
  }
}

class ExpansionTiles extends StatefulWidget {
  const ExpansionTiles({super.key, required this.showDividers});

  final bool showDividers;

  @override
  State<ExpansionTiles> createState() => _ExpansionTilesState();
}

class _ExpansionTilesState extends State<ExpansionTiles> {
  bool leadingControlAffinity = false;

  void _onAffinityChanged(bool value) {
    setState(() {
      leadingControlAffinity = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListCard(
      titleText: 'Expansion Tiles',
      showDividers: widget.showDividers,
      controls: <Widget>[
        SwitchListTile(
          value: leadingControlAffinity,
          onChanged: _onAffinityChanged,
          title: const Text('Leading control affinity'),
        ),
      ],
      children: <Widget>[
        ExpansionTile(
          title: headline,
          showTopDividerWhenExpanded: !Theme.of(context).useMaterial3,
          controlAffinity: leadingControlAffinity
              ? ListTileControlAffinity.leading
              : ListTileControlAffinity.trailing,
          children: const <Widget>[
            ListTile(title: Text('Expanding item 1')),
            ListTile(title: Text('Expanding item 2')),
            ListTile(title: Text('Expanding item 3')),
          ],
        ),
        ExpansionTile(
          title: headline,
          subtitle: supportingText,
          showTopDividerWhenExpanded: true, //!Theme.of(context).useMaterial3,
          controlAffinity: leadingControlAffinity
              ? ListTileControlAffinity.leading
              : ListTileControlAffinity.trailing,
          children: const <Widget>[
            ListTile(title: Text('Expanding item 1')),
            ListTile(title: Text('Expanding item 2')),
            ListTile(title: Text('Expanding item 3')),
          ],
        ),
        ExpansionTile(
          title: headline,
          overline: supportingText,
          showTopDividerWhenExpanded: !Theme.of(context).useMaterial3,
          controlAffinity: leadingControlAffinity
              ? ListTileControlAffinity.leading
              : ListTileControlAffinity.trailing,
          children: const <Widget>[
            ListTile(title: Text('Expanding item 1')),
            ListTile(title: Text('Expanding item 2')),
            ListTile(title: Text('Expanding item 3')),
          ],
        ),
        ExpansionTile(
          title: headline,
          subtitle: supportingText,
          showTopDividerWhenExpanded: !Theme.of(context).useMaterial3,
          leading: avatar,
          controlAffinity: leadingControlAffinity
              ? ListTileControlAffinity.leading
              : ListTileControlAffinity.trailing,
          children: const <Widget>[
            ListTile(title: Text('Expanding item 1')),
            ListTile(title: Text('Expanding item 2')),
            ListTile(title: Text('Expanding item 3')),
          ],
        ),
        ExpansionTile(
          title: headline,
          subtitle: supportingText,
          showTopDividerWhenExpanded: !Theme.of(context).useMaterial3,
          leading: leadingVideo,
          leadingConstraint: ListTileConstraint.video,
          controlAffinity: leadingControlAffinity
              ? ListTileControlAffinity.leading
              : ListTileControlAffinity.trailing,
          children: const <Widget>[
            ListTile(title: Text('Expanding item 1')),
            ListTile(title: Text('Expanding item 2')),
            ListTile(title: Text('Expanding item 3')),
          ],
        ),
        ExpansionTile(
          title: headline,
          overline: supportingText,
          subtitle: supportingText,
          isThreeLine: true,
          showTopDividerWhenExpanded: !Theme.of(context).useMaterial3,
          controlAffinity: leadingControlAffinity
              ? ListTileControlAffinity.leading
              : ListTileControlAffinity.trailing,
          children: const <Widget>[
            ListTile(title: Text('Expanding item 1')),
            ListTile(title: Text('Expanding item 2')),
            ListTile(title: Text('Expanding item 3')),
          ],
        ),
      ],
    );
  }
}

class ListCard extends StatelessWidget {
  const ListCard({
    super.key,
    required this.titleText,
    required this.showDividers,
    this.controls,
    required this.children,
  });

  final String titleText;
  final bool showDividers;
  final List<Widget>? controls;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: cardWidth),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            children: <Widget>[
              Container(
                alignment: Alignment.topLeft,
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(
                  titleText,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 16.0),
              if (controls != null) ...controls!,
              ColoredBox(
                color: Theme.of(context).colorScheme.surface,
                child: Material(
                  child: Column(
                    children: showDividers
                      ? ListTile.divideTiles(context: context, tiles: children)
                          .toList()
                      : children,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({
    super.key,
    required this.height,
    required this.width,
  });

  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: ImagePainter(),
      child: Container(
        width: width,
        height: height,
        // clipBehavior: Clip.hardEdge,
        color: Colors.grey.shade300,
      ),
    );
  }
}

class ToggleBooleanState extends StatefulWidget {
  const ToggleBooleanState({super.key, required this.builder});

  final Widget Function(bool value, void Function(bool value) onChanged)
      builder;

  @override
  State<ToggleBooleanState> createState() => _ToggleBooleanStateState();
}

class _ToggleBooleanStateState extends State<ToggleBooleanState> {
  bool value = true;

  void _onChanged(bool value) {
    setState(() {
      this.value = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(value, _onChanged);
  }
}

class ImagePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = Colors.black26;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double objectWidth = size.width / 3;
    final double offset = size.width / 5;

    Path triangle({required Offset center, required double width}) {
      final double height = 0.5 * width * math.sqrt(3.0);
      final Offset top = center.translate(0.0, -height / 2.0);
      final Offset bottomRight = top.translate(width / 2.0, height);
      final Offset bottomLeft = bottomRight.translate(-width, 0.0);
      return Path()
        ..moveTo(top.dx, top.dy)
        ..lineTo(bottomRight.dx, bottomRight.dy)
        ..lineTo(bottomLeft.dx, bottomLeft.dy)
        ..lineTo(top.dx, top.dy);
    }

    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawCircle(center.translate(offset, offset), objectWidth / 2, paint);
    canvas.drawRect(
      Rect.fromCircle(
        center: center.translate(-offset, offset),
        radius: objectWidth / 2.4,
      ),
      paint,
    );
    canvas.drawPath(
      triangle(
        center: center.translate(0.0, -offset),
        width: objectWidth,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
