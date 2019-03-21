import 'package:flutter/material.dart';

// A generic widget for a list of selectable colors
class ColorPicker extends StatelessWidget {
  const ColorPicker({
    @required this.colors,
    @required this.selectedColor,
    this.onTapColor,
  });

  final Set<Color> colors;
  final Color selectedColor;
  final Function(Color) onTapColor;

  @override
  Widget build (BuildContext context) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: colors.map((Color color) => ColorPickerSwatch(
          color: color,
          selected: color == selectedColor,
          onTap: () {
            if (onTapColor == null) {
              return;
            }
            onTapColor(color);
          },
        )).toList(),
      ),
    );
  }
}

// A single selectable color widget in the ColorPicker
class ColorPickerSwatch extends StatelessWidget {
  const ColorPickerSwatch({
    @required this.color,
    @required this.selected,
    this.onTap,
  });

  final Color color;
  final bool selected;
  final Function onTap;

  @override
  Widget build (BuildContext context) {
    return Container(
      child: Container(
        width: 60,
        height: 60,
        padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
        child: Stack(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                border: Border.all(width: 2.0, color: const Color(0xff000000)),
              ),
              child: Material(
                color: color,
                child: InkWell(
                  onTap: () {
                    if (onTap == null) {
                      return;
                    }
                    onTap();
                  },
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: !selected ? null : const Icon(
                Icons.check,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
