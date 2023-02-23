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

final List<Image> images = [
    // convert directly to ImageProvider instead of Image?
   
// what the heck is going on with england rugby color
    Image.asset('assets/yellow.png', height: 150,),
    Image.asset('assets/yellow_transparent.png', height: 150,),
    Image.asset('assets/yellow_full.png', height: 150,),
    Image.asset('assets/squares.png', height: 150,),
    Image.asset('assets/material_3_base.png', height: 150,),
    Image.asset('assets/rugby_japan.png', height: 150,),
    Image.asset('assets/football_leeds.png', height: 150,),
    Image.asset('assets/rugby_england.png', height: 150,),
];

  @override
  State<DynamicColorExample> createState() => _DynamicColorExampleState();
}

class _DynamicColorExampleState extends State<DynamicColorExample> {
    final TextEditingController _textFieldController = TextEditingController();
    late ColorScheme currentColorScheme;

    void initState() {
        currentColorScheme = ColorScheme.light();
    }

    void _updateImage(Image image) async {
        print('generating new colorScheme');
        // TODO add fail handling.
        final newColorScheme = await ColorScheme.fromImage(image: image);
        print('calling setState');
        setState(() { currentColorScheme = newColorScheme;
        print('colorschemeUpdated via setState: ${currentColorScheme.primary}');
    });
    }


    Future<void> networkAssetDialog(BuildContext context) async {
            late String input = 'url';
     showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Image URL'),
          content: TextField(
            onChanged: (value) { input = value;},
            controller: _textFieldController,
            decoration: InputDecoration(hintText: input),
            ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                    Navigator.pop(context, 'Cancel');
                 },
              child: const Text('Cancel'),
            ),
            TextButton(
                child: const Text('Submit'),
                onPressed: () async {
                    print('input: $input');
                 try {
                    // https://upload.wikimedia.org/wikipedia/commons/6/63/Wikipedia-logo.png
                    // wiki links seem to work but general URLs do not
                    final newColorScheme = await ColorScheme.fromImage(image: Image.network(input));
                    setState(() {
                        currentColorScheme = newColorScheme;
                        Navigator.pop(context, 'Submit');
                    });
                } on Exception catch (exception) {
                print('image load failed');
                input = 'not a valid url';
                }
              },
            ),
          ],
          ),
        );
    }

    @override
    Widget build(BuildContext context) {
        print('rebuilding!');
        final colorScheme = currentColorScheme;
        final selectedColor = colorScheme.primary;

        ThemeData lightTheme = ThemeData(
            colorSchemeSeed: selectedColor,
            brightness: Brightness.light,
        );
        ThemeData darkTheme = ThemeData(
            colorSchemeSeed: selectedColor,
            brightness: Brightness.dark,
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



        return  MaterialApp(
                title: 'Content Based Dynamic Color',
                theme: ThemeData(
                    useMaterial3: true,
                    colorScheme: colorScheme
                ),
                home: Builder(
                    builder: (BuildContext context) => Scaffold(
                    appBar: AppBar(
                        title: const Text('Content Based Dynamic Color'),
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                    ),
                    body: Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                                Row(mainAxisAlignment: MainAxisAlignment.center,
                                    children: [...widget.images.map((image) =>
                                    GestureDetector(
                                        onTap: () => _updateImage(image),
                                        child: Card(
                                            child: Padding(padding: EdgeInsets.all(10.0), child: image,),
                                        ))).toList(),
                                        GestureDetector(
                                            onTap: () => networkAssetDialog(context),
                                            child: Card(child: Padding(padding: EdgeInsets.all(10.0), child: Container(height: 150, child:Icon(Icons.link, size: 96.0)))
                                            ,),
                                        ),
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
    final brightness = ThemeData.estimateBrightnessForColor(color);
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

    return Container(
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
