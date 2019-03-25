import 'dart:ui' show Vertices;
import 'package:flutter/material.dart';
import 'pan_and_zoom_demo_board.dart';
import 'pan_and_zoom_demo_edit_board_point.dart';
import 'pan_and_zoom_demo_transform_interaction.dart';

class PanAndZoomDemo extends StatefulWidget {
  const PanAndZoomDemo({Key key}) : super(key: key);

  static const String routeName = '/pan_and_zoom';

  @override _PanAndZoomDemoState createState() => _PanAndZoomDemoState();
}
class _PanAndZoomDemoState extends State<PanAndZoomDemo> {
  static const double _kHexagonRadius = 32.0;
  static const double _kHexagonMargin = 1.0;
  static const int _kBorderRadius = 8;

  bool _reset = false;
  Board _board = Board(
    boardRadius: _kBorderRadius,
    hexagonRadius: _kHexagonRadius,
    hexagonMargin: _kHexagonMargin,
  );

  @override
  Widget build (BuildContext context) {
    final BoardPainter painter = BoardPainter(
      board: _board,
    );
    final Size screenSize = MediaQuery.of(context).size;
    final Size visibleSize = Size(screenSize.width * 3, screenSize.height * 2);

    final FloatingActionButton floatingActionButton = _board.selected == null
      ? FloatingActionButton(
        onPressed: () => setState(() {
          _reset = true;
        }),
        tooltip: 'Reset Transform',
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.home),
      )
      : FloatingActionButton(
        onPressed: () {
          if (_board.selected == null) {
            return;
          }
          showModalBottomSheet<Widget>(context: context, builder: (BuildContext context) {
            return EditBoardPoint(
              boardPoint: _board.selected,
              onSetColor: (Color color) {
                setState(() {
                  _board = _board.setBoardPointColor(_board.selected, color);
                  Navigator.pop(context);
                });
              },
            );
          });
        },
        tooltip: 'Edit Tile',
        child: const Icon(Icons.edit),
      );

    // The scene is drawn by a CustomPaint, but user interaction is handled by
    // the TransformInteraction parent widget.
    return Scaffold(
      appBar: AppBar(),
      body: TransformInteraction(
        // TODO(justinmc): I'm not sure that I like this pattern that I came up
        // with for resetting TransformInteraction from the parent level. Would
        // a controller pattern be better, or is there something else?
        reset: _reset,
        onResetEnd: () {
          setState(() {
            _reset = false;
          });
        },
        child: CustomPaint(
          size: Size.infinite,
          painter: painter,
        ),
        visibleRect: Rect.fromLTWH(
          -visibleSize.width / 2,
          -visibleSize.height / 2,
          visibleSize.width,
          visibleSize.height,
        ),
        // Center the board in the middle of the screen. It's drawn centered at
        // the origin, which is the top left corner of the TransformInteraction.
        initialTranslation: Offset(screenSize.width / 2, screenSize.height / 2),
        onTapUp: _onTapUp,
        size: screenSize,
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  void _onTapUp(Offset scenePoint) {
    final BoardPoint boardPoint = _board.pointToBoardPoint(scenePoint);
    setState(() {
      _board = _board.selectBoardPoint(boardPoint);
    });
  }
}

// CustomPainter is what is passed to CustomPaint and actually draws the scene
// when its `paint` method is called.
class BoardPainter extends CustomPainter {
  BoardPainter({
    this.board,
  });

  Board board;

  @override
  void paint(Canvas canvas, Size size) {
    void drawBoardPoint(BoardPoint boardPoint) {
      final Color color = board.selected == boardPoint
        ? boardPoint.color.withOpacity(0.2) : boardPoint.color;
      final Vertices vertices = board.getVerticesForBoardPoint(boardPoint, color);
      canvas.drawVertices(vertices, BlendMode.color, Paint());
    }

    board.forEach(drawBoardPoint);
  }

  // We should repaint whenever the board changes, such as board.selected.
  @override
  bool shouldRepaint(BoardPainter oldDelegate) {
    return oldDelegate.board != board;
  }
}
