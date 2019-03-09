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
  static const double HEXAGON_RADIUS = 32.0;
  static const double HEXAGON_MARGIN = 1.0;
  static const int BOARD_RADIUS = 8;

  Board _board = Board(
    boardRadius: BOARD_RADIUS,
    hexagonRadius: HEXAGON_RADIUS,
    hexagonMargin: HEXAGON_MARGIN,
  );

  @override
  Widget build (BuildContext context) {
    final BoardPainter painter = BoardPainter(
      board: _board,
    );
    final Size screenSize = MediaQuery.of(context).size;
    final Size visibleSize = Size(screenSize.width * 3, screenSize.height * 3);

    // The scene is drawn by a CustomPaint, but user interaction is handled by
    // the TransformInteraction parent widget.
    return Scaffold(
      body: TransformInteraction(
        //child: Text('hello world'),
        /*
        child: Image.asset(
          'places/india_pondicherry_salt_farm.png',
          package: 'flutter_gallery_assets',
          fit: BoxFit.cover,
        ),
        visibleRect: Rect.fromLTWH(
          -screenSize.width,
          -screenSize.height,
          visibleSize.width,
          visibleSize.height,
        ),
        */
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
        initialTranslation: Offset(screenSize.width / 2, screenSize.height / 2),
        onTapUp: _onTapUp,
        size: screenSize,
      ),
      floatingActionButton: _board.selected == null ? null : FloatingActionButton(
        onPressed: () => setState(() {
          if (_board.selected == null) {
            return;
          }
          showModalBottomSheet<Widget>(context: context, builder: (BuildContext context) {
            // TODO(justinmc): I think storing the selected board point gives
            // you an outdated color. Duplicate info.
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
        }),
        tooltip: 'Edit Tile',
        child: const Icon(Icons.edit),
      ),
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
