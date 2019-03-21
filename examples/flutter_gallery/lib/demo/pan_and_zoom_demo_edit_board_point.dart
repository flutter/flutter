import 'package:flutter/material.dart';
import 'pan_and_zoom_demo_board.dart';
import 'pan_and_zoom_demo_color_picker.dart';

// The panel for editing a board point
class EditBoardPoint extends StatelessWidget {
  const EditBoardPoint({
    Key key,
    @required this.boardPoint,
    this.onSetColor,
  }) : super(key: key);

  final BoardPoint boardPoint;
  final Function(Color) onSetColor;

  @override
  Widget build (BuildContext context) {
    return Container(
      width: double.infinity,
      height: 150,
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            '${boardPoint.q}, ${boardPoint.r}',
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          ColorPicker(
            colors: boardPointColors,
            selectedColor: boardPoint.color,
            onTapColor: onSetColor,
          ),
        ],
      ),
    );
  }
}
