// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for [ColorScheme] with content-based dynamic color.

import 'package:flutter/material.dart';

const Widget divider = SizedBox(height: 10);
const double narrowScreenWidthThreshold = 400;

void main() => runApp(DynamicColorExample());

class DynamicColorExample extends StatefulWidget {
  DynamicColorExample({super.key});

  final Map<Image, String> images = {
    Image.asset(
      'assets/yellow.png',
      height: 150,
    ): 'as expected',
    Image.asset(
      'assets/yellow_transparent.png',
      height: 150,
    ): 'as expected',
    Image.asset(
      'assets/yellow_full.png',
      height: 150,
    ): 'expected previous yellow',
    Image.asset(
      'assets/squares.png',
      height: 150,
    ): 'expected green',
    Image.asset(
      'assets/material_3_base.png',
      height: 150,
    ): 'Material 3 base: as expected',
    Image.asset(
      'assets/rugby_japan.png',
      height: 150,
    ): 'expected pink',
    Image.asset(
      'assets/football_leeds.png',
      height: 150,
    ): 'as expected',
    Image.asset(
      'assets/rugby_england.png',
      height: 150,
    ): 'very unexpected',
  };

  @override
  State<DynamicColorExample> createState() => _DynamicColorExampleState();
}

class _DynamicColorExampleState extends State<DynamicColorExample> {
  final TextEditingController _textFieldController = TextEditingController();
  late ColorScheme currentColorScheme;
  late int selectedImage;
  late bool isLight;
  @override
  void initState() {
    currentColorScheme = ColorScheme.light();
    selectedImage = 4;
    isLight = true;
  }

  Future<void> _updateImage(Image image) async {
    // TODO add fail handling.
    final ColorScheme newColorScheme = await ColorScheme.fromImage(
        image: image, brightness: isLight ? Brightness.light : Brightness.dark);
    setState(() {
      selectedImage = widget.images.keys.toList().indexOf(image) ??
          widget.images.length + 1;
      currentColorScheme = newColorScheme;
    });
  }

  // Image uploader

  // Future<void> networkAssetDialog(BuildContext context) async {
  //   late String input = 'url';
  //   showDialog<String>(
  //     context: context,
  //     builder: (BuildContext context) => AlertDialog(
  //       title: const Text('Image URL'),
  //       content: TextField(
  //         onChanged: (value) {
  //           input = value;
  //         },
  //         controller: _textFieldController,
  //         decoration: InputDecoration(hintText: input),
  //       ),
  //       actions: <Widget>[
  //         TextButton(
  //           onPressed: () {
  //             Navigator.pop(context, 'Cancel');
  //           },
  //           child: const Text('Cancel'),
  //         ),
  //         TextButton(
  //           child: const Text('Submit'),
  //           onPressed: () async {
  //             print('input: $input');
  //             try {
  //               // https://upload.wikimedia.org/wikipedia/commons/6/63/Wikipedia-logo.png
  //               final newColorScheme =
  //                   await ColorScheme.fromImage(image: Image.network(input));
  //               setState(() {
  //                 currentColorScheme = newColorScheme;
  //                 Navigator.pop(context, 'Submit');
  //               });
  //             } on Exception catch (exception) {
  //               print('image load failed');
  //               input = 'not a valid url';
  //             }
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = currentColorScheme;
    final Color selectedColor = colorScheme.primary;

    final ThemeData lightTheme = ThemeData(
      colorSchemeSeed: selectedColor,
      brightness: Brightness.light,
      useMaterial3: true,
    );
    final ThemeData darkTheme = ThemeData(
      colorSchemeSeed: selectedColor,
      brightness: Brightness.dark,
      useMaterial3: true,
    );

    Widget schemeLabel(String brightness) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Text(
          brightness,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }

    Widget schemeView(ThemeData theme) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: ColorSchemeView(
          colorScheme: theme.colorScheme,
        ),
      );
    }

    return MaterialApp(
      title: 'Content Based Dynamic Color',
      theme: ThemeData(useMaterial3: true, colorScheme: colorScheme),
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (BuildContext context) => Scaffold(
          appBar: AppBar(
            title: const Text('Content Based Dynamic Color'),
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            actions: [
              Icon(Icons.light_mode),
              Switch(
                  activeColor: colorScheme.primary,
                  activeTrackColor: colorScheme.surface,
                  inactiveTrackColor: colorScheme.onSecondary,
                  value: isLight,
                  onChanged: (bool value) {
                    setState(() {
                      isLight = value;
                      _updateImage(widget.images.keys.toList()[selectedImage]);
                    });
                  })
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    ...widget.images.keys
                        .map((image) => GestureDetector(
                            onTap: () => _updateImage(image),
                            child: Card(
                              color:
                                  widget.images.keys.toList().indexOf(image) ==
                                          selectedImage
                                      ? colorScheme.surfaceVariant
                                      : null,
                              child: Padding(
                                padding: EdgeInsets.all(10.0),
                                child: Column(
                                  children: [
                                    image,
                                    Text(widget.images[image] ?? ''),
                                  ],
                                ),
                              ),
                            )))
                        .toList(),
                    // Image upload tile
                    // GestureDetector(
                    //   onTap: () => networkAssetDialog(context),
                    //   child: Card(
                    //     child: Padding(
                    //         padding: EdgeInsets.all(10.0),
                    //         child: Container(
                    //             height: 150,
                    //             child: Icon(Icons.link, size: 96.0))),
                    //   ),
                    // ),
                  ],
                ),
                Expanded(
                  child: LayoutBuilder(builder: (context, constraints) {
                    if (constraints.maxWidth < narrowScreenWidthThreshold) {
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            divider,
                            schemeLabel('Light ColorScheme'),
                            schemeView(lightTheme),
                            divider,
                            divider,
                            schemeLabel('Dark ColorScheme'),
                            schemeView(darkTheme),
                          ],
                        ),
                      );
                    } else {
                      return SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        schemeLabel('Light ColorScheme'),
                                        schemeView(lightTheme),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        schemeLabel('Dark ColorScheme'),
                                        schemeView(darkTheme),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ColorSchemeView extends StatelessWidget {
  const ColorSchemeView({super.key, required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ColorGroup(children: [
          ColorChip(
            label: 'primary',
            color: colorScheme.primary,
            onColor: colorScheme.onPrimary,
          ),
          ColorChip(
              label: 'onPrimary',
              color: colorScheme.onPrimary,
              onColor: colorScheme.primary),
          ColorChip(
            label: 'primaryContainer',
            color: colorScheme.primaryContainer,
            onColor: colorScheme.onPrimaryContainer,
          ),
          ColorChip(
            label: 'onPrimaryContainer',
            color: colorScheme.onPrimaryContainer,
            onColor: colorScheme.primaryContainer,
          ),
        ]),
        divider,
        ColorGroup(children: [
          ColorChip(
            label: 'secondary',
            color: colorScheme.secondary,
            onColor: colorScheme.onSecondary,
          ),
          ColorChip(
            label: 'onSecondary',
            color: colorScheme.onSecondary,
            onColor: colorScheme.secondary,
          ),
          ColorChip(
            label: 'secondaryContainer',
            color: colorScheme.secondaryContainer,
            onColor: colorScheme.onSecondaryContainer,
          ),
          ColorChip(
              label: 'onSecondaryContainer',
              color: colorScheme.onSecondaryContainer,
              onColor: colorScheme.secondaryContainer),
        ]),
        divider,
        ColorGroup(
          children: [
            ColorChip(
                label: 'tertiary',
                color: colorScheme.tertiary,
                onColor: colorScheme.onTertiary),
            ColorChip(
                label: 'onTertiary',
                color: colorScheme.onTertiary,
                onColor: colorScheme.tertiary),
            ColorChip(
                label: 'tertiaryContainer',
                color: colorScheme.tertiaryContainer,
                onColor: colorScheme.onTertiaryContainer),
            ColorChip(
                label: 'onTertiaryContainer',
                color: colorScheme.onTertiaryContainer,
                onColor: colorScheme.tertiaryContainer),
          ],
        ),
        divider,
        ColorGroup(
          children: [
            ColorChip(
                label: 'error',
                color: colorScheme.error,
                onColor: colorScheme.onError),
            ColorChip(
                label: 'onError',
                color: colorScheme.onError,
                onColor: colorScheme.error),
            ColorChip(
                label: 'errorContainer',
                color: colorScheme.errorContainer,
                onColor: colorScheme.onErrorContainer),
            ColorChip(
                label: 'onErrorContainer',
                color: colorScheme.onErrorContainer,
                onColor: colorScheme.errorContainer),
          ],
        ),
        divider,
        ColorGroup(
          children: [
            ColorChip(
                label: 'background',
                color: colorScheme.background,
                onColor: colorScheme.onBackground),
            ColorChip(
                label: 'onBackground',
                color: colorScheme.onBackground,
                onColor: colorScheme.background),
          ],
        ),
        divider,
        ColorGroup(
          children: [
            ColorChip(
                label: 'surface',
                color: colorScheme.surface,
                onColor: colorScheme.onSurface),
            ColorChip(
                label: 'onSurface',
                color: colorScheme.onSurface,
                onColor: colorScheme.surface),
            ColorChip(
                label: 'surfaceVariant',
                color: colorScheme.surfaceVariant,
                onColor: colorScheme.onSurfaceVariant),
            ColorChip(
                label: 'onSurfaceVariant',
                color: colorScheme.onSurfaceVariant,
                onColor: colorScheme.surfaceVariant),
          ],
        ),
        divider,
        ColorGroup(
          children: [
            ColorChip(label: 'outline', color: colorScheme.outline),
            ColorChip(label: 'shadow', color: colorScheme.shadow),
            ColorChip(
                label: 'inverseSurface',
                color: colorScheme.inverseSurface,
                onColor: colorScheme.onInverseSurface),
            ColorChip(
                label: 'onInverseSurface',
                color: colorScheme.onInverseSurface,
                onColor: colorScheme.inverseSurface),
            ColorChip(
                label: 'inversePrimary',
                color: colorScheme.inversePrimary,
                onColor: colorScheme.primary),
          ],
        ),
      ],
    );
  }
}

class ColorGroup extends StatelessWidget {
  const ColorGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: children,
        ),
      ),
    );
  }
}

class ColorChip extends StatelessWidget {
  const ColorChip({
    super.key,
    required this.color,
    required this.label,
    this.onColor,
  });

  final Color color;
  final Color? onColor;
  final String label;

  static Color contrastColor(Color color) {
    final Brightness brightness = ThemeData.estimateBrightnessForColor(color);
    switch (brightness) {
      case Brightness.dark:
        return Colors.white;
      case Brightness.light:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color labelColor = onColor ?? contrastColor(color);

    return ColoredBox(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(color: labelColor))),
          ],
        ),
      ),
    );
  }
}
