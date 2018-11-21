import 'package:flutter/material.dart';
import 'package:flutter_gallery/demo/playground/configuration/property_column.dart';

const double _pickerSelectedElevation = 3.0;
const double _pickerRowHeight = 46.0;

typedef IndexedValueCallback<T> = Function(int index, T value);

// pickers
Widget sliderPicker({
  @required String label,
  double value = 0.0,
  double minValue = 0.0,
  double maxValue = 1.0,
  int divisions,
  ValueChanged<double> onValueChanged,
}) {
  return PropertyColumn(
    label: label,
    widget: Padding(
      padding: const EdgeInsets.only(bottom: 5.0),
      child: Slider(
        value: value,
        min: minValue,
        max: maxValue,
        divisions: divisions,
        onChanged: onValueChanged,
      ),
    ),
  );
}

ShapeBorder borderShapeFromString(String type, [bool side = true]) {
  ShapeBorder shape;

  BorderSide borderSide = const BorderSide(
    color: Colors.grey,
    width: 2.0,
  );

  borderSide = side ? borderSide : BorderSide.none;

  switch (type) {
    case 'box':
      shape = RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, side: borderSide);
      break;
    case 'rounded':
      shape = RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0), side: borderSide);
      break;
    case 'beveled':
      shape = BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
          side: borderSide.copyWith(width: 1.0));
      break;
    case 'circle':
      shape = CircleBorder(side: borderSide);
      break;
  }
  return shape;
}

Widget shapeButton({
  @required String shape,
  Size size = const Size(_pickerRowHeight, _pickerRowHeight),
  bool isSelected = false,
  VoidCallback onTapped,
}) {
  return ButtonTheme(
    minWidth: size.width,
    height: size.height,
    child: RaisedButton(
      shape: borderShapeFromString(shape),
      color: isSelected ? Colors.blue : Colors.white,
      elevation: isSelected ? _pickerSelectedElevation : 0.0,
      onPressed: onTapped,
    ),
  );
}

Widget shapePicker({
  double pickerHeight = _pickerRowHeight,
  String selectedValue,
  List<String> shapeNames,
  IndexedValueCallback<String> onItemTapped,
}) {
  final List<String> shapeNameOptions = shapeNames ??
      <String>[
        'box',
        'beveled',
        'rounded',
        'circle',
      ];
  final List<Widget> buttonChildren = <Widget>[];
  for (int i = 0; i < shapeNameOptions.length; i++) {
    final String shapeName = shapeNameOptions[i];
    Widget button = shapeButton(
      shape: shapeName,
      isSelected: selectedValue == shapeName,
      onTapped: () {
        if (onItemTapped != null) {
          onItemTapped(i, shapeName);
        }
      },
    );
    if (i < shapeNameOptions.length - 1) {
      button = Padding(
        padding: const EdgeInsets.only(right: 10.0),
        child: button,
      );
    }
    buttonChildren.add(button);
  }
  return PropertyColumn(
    label: 'Shape',
    widget: Container(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      height: pickerHeight,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: buttonChildren,
      ),
    ),
  );
}

Widget colorButton({
  @required Color color,
  Size size = const Size(_pickerRowHeight, _pickerRowHeight),
  bool isSelected = false,
  VoidCallback onTapped,
}) {
  return ButtonTheme(
    minWidth: size.width,
    height: size.height,
    child: RaisedButton(
      shape: StadiumBorder(
        side: BorderSide(
          color: isSelected ? Colors.white : Colors.grey[350],
          width: 2.0,
        ),
      ),
      color: color,
      elevation: isSelected ? _pickerSelectedElevation : 0.0,
      onPressed: onTapped,
    ),
  );
}

Widget colorPicker({
  double pickerHeight = _pickerRowHeight,
  String label = 'Color',
  Color selectedValue,
  List<Color> colors,
  IndexedValueCallback<Color> onItemTapped,
}) {
  final List<Color> colorOptions = colors ??
      <Color>[
        Colors.white,
        Colors.orange,
        Colors.cyan[200],
        Colors.lightBlue[300],
        Colors.blue,
        Colors.blue[800],
      ];
  final List<Widget> buttonChildren = <Widget>[];
  for (int i = 0; i < colorOptions.length; i++) {
    final Color color = colorOptions[i];
    Widget button = colorButton(
      color: color,
      isSelected: selectedValue == color,
      onTapped: () {
        if (onItemTapped != null) {
          onItemTapped(i, color);
        }
      },
    );
    if (i < colorOptions.length - 1) {
      button = Padding(
        padding: const EdgeInsets.only(right: 10.0),
        child: button,
      );
    }
    buttonChildren.add(button);
  }
  return PropertyColumn(
    label: label,
    widget: Container(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      height: pickerHeight,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: buttonChildren,
      ),
    ),
  );
}

Widget buttonListContainer(List<Widget> children, {double height = _pickerRowHeight}) {
  return Container(
    padding: const EdgeInsets.only(bottom: 20.0),
    height: height,
    child: ListView(
      padding: const EdgeInsets.all(10.0),
      scrollDirection: Axis.horizontal,
      children: children,
    ),
  );
}
