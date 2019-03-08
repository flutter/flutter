import 'package:flutter/material.dart';

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
      decoration: BoxDecoration(
        border: Border.all(width: 1.0, color: Colors.black),
      ),
      child: Row(
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
    return InkWell(
      onTap: () {
        if (onTap == null) {
          return;
        }
        onTap();
      },
      child: Container(
        width: 60,
        height: 60,
        child: Stack(
          children: <Widget>[
            Container(
              color: color,
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: !selected ? null : const Icon(Icons.check),
            ),
          ],
        ),
      ),
    );
  }
}
