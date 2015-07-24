// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library mine_digger;

import 'dart:sky' as sky;
import 'dart:math';

import 'package:sky/painting/text_style.dart';
import 'package:sky/rendering/flex.dart';
import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/widget.dart';
import 'package:sky/widgets/scaffold.dart';
import 'package:sky/widgets/task_description.dart';
import 'package:sky/widgets/theme.dart';
import 'package:sky/widgets/tool_bar.dart';

// Classic minesweeper-inspired game. The mouse controls are standard
// except for left + right combo which is not implemented. For touch,
// the duration of the pointer determines probing versus flagging.
//
// There are only 3 classes to understand. MineDiggerApp, which is
// contains all the logic and two classes that describe the mines:
// CoveredMineNode and ExposedMineNode, none of them holding state.

// Colors for each mine count (0-8):
const List<TextStyle> textStyles = const <TextStyle>[
  const TextStyle(color: const Color(0xFF555555), fontWeight: bold),
  const TextStyle(color: const Color(0xFF0094FF), fontWeight: bold), // blue
  const TextStyle(color: const Color(0xFF13A023), fontWeight: bold), // green
  const TextStyle(color: const Color(0xFFDA1414), fontWeight: bold), // red
  const TextStyle(color: const Color(0xFF1E2347), fontWeight: bold), // black
  const TextStyle(color: const Color(0xFF7F0037), fontWeight: bold), // dark red
  const TextStyle(color: const Color(0xFF000000), fontWeight: bold),
  const TextStyle(color: const Color(0xFF000000), fontWeight: bold),
  const TextStyle(color: const Color(0xFF000000), fontWeight: bold),
];

enum CellState { covered, exploded, cleared, flagged, shown }

class MineDiggerApp extends App {
  static const int rows = 9;
  static const int cols = 9;
  static const int totalMineCount = 11;

  bool alive;
  bool hasWon;
  int detectedCount;

  // |cells| keeps track of the positions of the mines.
  List<List<bool>> cells;
  // |uiState| keeps track of the visible player progess.
  List<List<CellState>> uiState;

  void initState() {
    resetGame();
  }

  void resetGame() {
    alive = true;
    hasWon = false;
    detectedCount = 0;
    // Build the arrays.
    cells = new List<List<bool>>();
    uiState = new List<List<CellState>>();
    for (int iy = 0; iy != rows; iy++) {
      cells.add(new List<bool>());
      uiState.add(new List<CellState>());
      for (int ix = 0; ix != cols; ix++) {
        cells[iy].add(false);
        uiState[iy].add(CellState.covered);
      }
    }
    // Place the mines.
    Random random = new Random();
    int cellsRemaining = rows * cols;
    int minesRemaining = totalMineCount;
    for (int x = 0; x < cols; x += 1) {
      for (int y = 0; y < rows; y += 1) {
        if (random.nextInt(cellsRemaining) < minesRemaining) {
          cells[y][x] = true;
          minesRemaining -= 1;
          if (minesRemaining <= 0)
            return;
        }
        cellsRemaining -= 1;
      }
    }
    assert(false);
  }

  Stopwatch longPressStopwatch;

  PointerEventListener _pointerDownHandlerFor(int posX, int posY) {
    return (sky.PointerEvent event) {
      if (event.buttons == 1) {
        probe(posX, posY);
      } else if (event.buttons == 2) {
        flag(posX, posY);
      } else {
        // Touch event.
        longPressStopwatch = new Stopwatch()..start();
      }
    };
  }

  PointerEventListener _pointerUpHandlerFor(int posX, int posY) {
    return (sky.PointerEvent event) {
      if (longPressStopwatch == null)
        return;
      // Pointer down was a touch event.
      if (longPressStopwatch.elapsedMilliseconds < 250) {
        probe(posX, posY);
      } else {
        // Long press flags.
        flag(posX, posY);
      }
      longPressStopwatch = null;
    };
  }

  Widget buildBoard() {
    bool hasCoveredCell = false;
    List<Flex> flexRows = <Flex>[];
    for (int iy = 0; iy != 9; iy++) {
      List<Widget> row = <Widget>[];
      for (int ix = 0; ix != 9; ix++) {
        CellState state = uiState[iy][ix];
        int count = mineCount(ix, iy);
        if (!alive) {
          if (state != CellState.exploded)
            state = cells[iy][ix] ? CellState.shown : state;
        }
        if (state == CellState.covered) {
          row.add(new Listener(
            onPointerDown: _pointerDownHandlerFor(ix, iy),
            onPointerUp: _pointerUpHandlerFor(ix, iy),
            child: new CoveredMineNode(
              flagged: false,
              posX: ix,
              posY: iy
            )
          ));
          // Mutating |hasCoveredCell| here is hacky, but convenient, same
          // goes for mutating |hasWon| below.
          hasCoveredCell = true;
        } else if (state == CellState.flagged) {
          row.add(new CoveredMineNode(
            flagged: true,
            posX: ix,
            posY: iy
          ));
        } else {
          row.add(new ExposedMineNode(
            state: state,
            count: count
          ));
        }
      }
      flexRows.add(
        new Flex(
          row,
          direction: FlexDirection.horizontal,
          justifyContent: FlexJustifyContent.center,
          key: new Key.stringify(iy)
        )
      );
    }

    if (!hasCoveredCell) {
      // all cells uncovered. Are all mines flagged?
      if ((detectedCount == totalMineCount) && alive) {
        hasWon = true;
      }
    }

    return new Container(
      padding: new EdgeDims.all(10.0),
      margin: new EdgeDims.all(10.0),
      decoration: new BoxDecoration(backgroundColor: const Color(0xFF6B6B6B)),
      child: new Flex(
        flexRows,
        direction: FlexDirection.vertical
      )
    );
  }

  Widget buildToolBar() {
    String toolbarCaption = hasWon ?
      'Awesome!!' : alive ?
        'Mine Digger [$detectedCount-$totalMineCount]': 'Kaboom! [press here]';

    return new ToolBar(
      // FIXME: Strange to have the toolbar be tapable.
      center: new Listener(
        onPointerDown: handleToolbarPointerDown,
        child: new Text(toolbarCaption, style: Theme.of(this).text.title)
      )
    );
  }

  Widget build() {
    // We build the board before we build the toolbar because we compute the win state during build step.
    Widget board = buildBoard();
    return new TaskDescription(
      label: 'Mine Digger',
      child: new Scaffold(
        toolbar: buildToolBar(),
        body: new Container(
          child: new Center(child: board),
          decoration: new BoxDecoration(backgroundColor: colors.Grey[50])
        )
      )
    );
  }

  void handleToolbarPointerDown(sky.PointerEvent event) {
    setState(() {
      resetGame();
    });
  }

  // User action. The user uncovers the cell which can cause losing the game.
  void probe(int x, int y) {
    if (!alive)
      return;
    if (uiState[y][x] == CellState.flagged)
      return;
    setState(() {
      // Allowed to probe.
      if (cells[y][x]) {
        // Probed on a mine --> dead!!
        uiState[y][x] = CellState.exploded;
        alive = false;
      } else {
        // No mine, uncover nearby if possible.
        cull(x, y);
      }
    });
  }

  // User action. The user is sure a mine is at this location.
  void flag(int x, int y) {
    setState(() {
      if (uiState[y][x] == CellState.flagged) {
        uiState[y][x] = CellState.covered;
        --detectedCount;
      } else {
        uiState[y][x] = CellState.flagged;
        ++detectedCount;
      }
    });
  }

  // Recursively uncovers cells whose totalMineCount is zero.
  void cull(int x, int y) {
    if ((x < 0) || (x > rows - 1))
      return;
    if ((y < 0) || (y > cols - 1))
      return;

    if (uiState[y][x] == CellState.cleared)
      return;
    uiState[y][x] = CellState.cleared;

    if (mineCount(x, y) > 0)
      return;

    cull(x - 1, y);
    cull(x + 1, y);
    cull(x, y - 1);
    cull(x, y + 1 );
    cull(x - 1, y - 1);
    cull(x + 1, y + 1);
    cull(x + 1, y - 1);
    cull(x - 1, y + 1);
  }

  int mineCount(int x, int y) {
    int count = 0;
    int my = cols - 1;
    int mx = rows - 1;

    count += x > 0 ? bombs(x - 1, y) : 0;
    count += x < mx ? bombs(x + 1, y) : 0;
    count += y > 0 ? bombs(x, y - 1) : 0;
    count += y < my ? bombs(x, y + 1 ) : 0;

    count += (x > 0) && (y > 0) ? bombs(x - 1, y - 1) : 0;
    count += (x < mx) && (y < my) ? bombs(x + 1, y + 1) : 0;
    count += (x < mx) && (y > 0) ? bombs(x + 1, y - 1) : 0;
    count += (x > 0) && (y < my) ? bombs(x - 1, y + 1) : 0;

    return count;
  }

  int bombs(int x, int y) {
    return cells[y][x] ? 1 : 0;
  }
}

Widget buildCell(Widget child) {
  return new Container(
    padding: new EdgeDims.all(1.0),
    height: 27.0, width: 27.0,
    decoration: new BoxDecoration(backgroundColor: const Color(0xFFC0C0C0)),
    margin: new EdgeDims.all(2.0),
    child: child
  );
}

Widget buildInnerCell(Widget child) {
  return new Container(
    padding: new EdgeDims.all(1.0),
    margin: new EdgeDims.all(3.0),
    height: 17.0, width: 17.0,
    child: child
  );
}

class CoveredMineNode extends Component {

  CoveredMineNode({ this.flagged, this.posX, this.posY });

  final bool flagged;
  final int posX;
  final int posY;

  Widget build() {
    Widget text;
    if (flagged)
      text = buildInnerCell(new StyledText(elements : [textStyles[5], '\u2691']));

    Container inner = new Container(
      margin: new EdgeDims.all(2.0),
      height: 17.0, width: 17.0,
      decoration: new BoxDecoration(backgroundColor: const Color(0xFFD9D9D9)),
      child: text
    );

    return buildCell(inner);
  }
}

class ExposedMineNode extends Component {

  ExposedMineNode({ this.state, this.count });

  final CellState state;
  final int count;

  Widget build() {
    StyledText text;
    if (state == CellState.cleared) {
      // Uncovered cell with nearby mine count.
      if (count != 0)
        text = new StyledText(elements : [textStyles[count], '$count']);
    } else {
      // Exploded mine or shown mine for 'game over'.
      int color = state == CellState.exploded ? 3 : 0;
      text = new StyledText(elements : [textStyles[color], '\u2600']);
    }
    return buildCell(buildInnerCell(text));
  }

}

void main() {
  runApp(new MineDiggerApp());
}
