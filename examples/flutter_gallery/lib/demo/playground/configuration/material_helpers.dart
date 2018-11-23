import 'package:flutter/material.dart';
import 'package:flutter_gallery/demo/playground/configuration/property_column.dart';

const double _pickerSelectedElevation = 3.0;
const double _pickerRowHeight = 46.0;

typedef IndexedValueCallback<T> = Function(int index, T value);

class BorderChoice {
  BorderChoice({@required this.type, @required this.code});
  String type;
  String code;
}

class ColorChoice {
  ColorChoice({@required this.color, @required this.code});
  Color color;
  String code;
}

class IconChoice {
  IconChoice({@required this.icon, @required this.code});
  IconData icon;
  String code;
}

final List<BorderChoice> kBorders = <BorderChoice>[
  BorderChoice(type: 'square', code: '''
RoundedRectangleBorder(
  borderRadius: BorderRadius.zero
)'''),
  BorderChoice(type: 'rounded', code: '''
RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(10.0)'
)'''),
  BorderChoice(type: 'beveled', code: '''
BeveledRectangleBorder(
  borderRadius: BorderRadius.circular(10.0)
)'''),
  BorderChoice(type: 'stadium', code: '''
StadiumBorder()'''),
];

final List<ColorChoice> kColors = <ColorChoice>[
  ColorChoice(color: Colors.white, code: 'Colors.white'),
  ColorChoice(color: Colors.orange, code: 'Colors.orange'),
  ColorChoice(color: Colors.cyan[200], code: 'Colors.cyan[200]'),
  ColorChoice(color: Colors.lightBlue[300], code: 'Colors.lightBlue[300]'),
  ColorChoice(color: Colors.blue, code: 'Colors.blue'),
  ColorChoice(color: Colors.blue[800], code: 'Colors.blue[800]'),
];

final List<IconChoice> kIcons = <IconChoice>[
  IconChoice(icon: Icons.thumb_up, code: 'Icons.thumb_up'),
  IconChoice(icon: Icons.android, code: 'Icons.android'),
  IconChoice(icon: Icons.alarm, code: 'Icons.alarm'),
  IconChoice(icon: Icons.accessibility, code: 'Icons.accessibility'),
  IconChoice(icon: Icons.call, code: 'Icons.call'),
  IconChoice(icon: Icons.camera, code: 'Icons.camera'),
];

final List<String> kBorderOptions =
    kBorders.map((BorderChoice b) => b.type).toList();

final List<Color> kColorOptions =
    kColors.map((ColorChoice c) => c.color).toList();

final List<IconData> kIconOptions =
    kIcons.map((IconChoice i) => i.icon).toList();

String codeSnippetForColor(Color color) {
  return kColors.where((ColorChoice c) => c.color == color).toList()[0].code;
}

String codeSnippetForBorder(String type) {
  return kBorders.where((BorderChoice b) => b.type == type).toList()[0].code;
}

String codeSnippetForIcon(IconData icon) {
  return kIcons.where((IconChoice b) => b.icon == icon).toList()[0].code;
}

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
    case 'square':
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
    case 'stadium':
      shape = StadiumBorder(side: borderSide);
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
        'square',
        'beveled',
        'rounded',
        'stadium',
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
  bool inverse = false,
  bool isSelected = false,
  VoidCallback onTapped,
}) {
  return ButtonTheme(
    minWidth: size.width,
    height: size.height,
    child: RaisedButton(
      shape: StadiumBorder(
        side: BorderSide(
          color:
              inverse ? color : (isSelected ? Colors.white : Colors.grey[350]),
          width: 2.0,
        ),
      ),
      color: inverse ? Colors.white : color,
      elevation: isSelected ? _pickerSelectedElevation : 0.0,
      onPressed: onTapped,
    ),
  );
}

Widget colorPicker({
  double pickerHeight = _pickerRowHeight,
  bool inverse = false,
  String label = 'Color',
  Color selectedValue,
  List<Color> colors,
  IndexedValueCallback<Color> onItemTapped,
}) {
  final List<Color> colorOptions = colors ?? kColorOptions;
  final List<Widget> buttonChildren = <Widget>[];
  for (int i = 0; i < colorOptions.length; i++) {
    final Color color = colorOptions[i];
    Widget button = colorButton(
      color: color,
      inverse: inverse,
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

Widget buttonListContainer(List<Widget> children,
    {double height = _pickerRowHeight}) {
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
