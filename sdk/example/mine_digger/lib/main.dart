// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;
import 'dart:math';

import 'package:sky/rendering/flex.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/scaffold.dart';
import 'package:sky/widgets/tool_bar.dart';
import 'package:sky/widgets/theme.dart';
import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/painting/text_style.dart';

// Classic minesweeper-inspired game. The mouse controls are standard except
// for left + right combo which is not implemented. For touch, the duration of
// the pointer determines probing versus flagging.
//
// There are only 3 classes to understand. Game, which is contains all the
// logic and two UI classes: CoveredMineNode and ExposedMineNode, none of them
// holding state.

class Game {
  static const int rows = 9;
  static const int cols = 9;
  static const int totalMineCount = 11;

  static const int coveredCell = 0;
  static const int explodedCell = 1;
  static const int clearedCell = 2;
  static const int flaggedCell = 3;
  static const int shownCell = 4;

  static final List<TextStyle> textStyles = new List<TextStyle>();

  final App app;

  bool alive;
  bool hasWon;
  int detectedCount;
  int randomSeed;

  // |cells| keeps track of the positions of the mines.
  List<List<bool>> cells;
  // |uiState| keeps track of the visible player progess.
  List<List<int>> uiState;

  Game(this.app) {
    randomSeed = 22;
    // Colors for each mine count:
    // 0 - none, 1 - blue, 2-green, 3-red, 4-black, 5-dark red .. etc.
    textStyles.add(
      new TextStyle(color: const Color(0xFF555555), fontWeight: bold));
    textStyles.add(
      new TextStyle(color: const Color(0xFF0094FF), fontWeight: bold));
    textStyles.add(
      new TextStyle(color: const Color(0xFF13A023), fontWeight: bold));
    textStyles.add(
      new TextStyle(color: const Color(0xFFDA1414), fontWeight: bold));
    textStyles.add(
      new TextStyle(color: const Color(0xFF1E2347), fontWeight: bold));
    textStyles.add(
      new TextStyle(color: const Color(0xFF7F0037), fontWeight: bold));
    textStyles.add(
      new TextStyle(color: const Color(0xFFE93BE9), fontWeight: bold));
    initialize();
  }

  void initialize() {
    alive = true;
    hasWon = false;
    detectedCount = 0;
    // Build the arrays.
    cells = new List<List<bool>>();
    uiState = new List<List<int>>();
    for (int iy = 0; iy != rows; iy++) {
      cells.add(new List<bool>());
      uiState.add(new List<int>());
      for (int ix = 0; ix != cols; ix++) {
        cells[iy].add(false);
        uiState[iy].add(coveredCell);
      }
    }
    // Place the mines.
    Random random = new Random(++randomSeed);
    for (int mc = 0; mc != totalMineCount; mc++) {
      int rx = random.nextInt(rows);
      int ry = random.nextInt(cols);
      if (cells[ry][rx]) {
        // Mine already there. Try again.
        --mc;
      } else {
        cells[ry][rx] = true;
      }
    }
  }

  Widget buildBoard() {
    bool hasCoveredCell = false;
    List<Flex> flexRows = new List<Flex>();
    for (int iy = 0; iy != 9; iy++) {
      List<Component> row = new List<Component>();
      for (int ix = 0; ix != 9; ix++) {
        int state = uiState[iy][ix];
        int count = mineCount(ix, iy);

        if (!alive) {
          if (state != explodedCell)
            state = cells[iy][ix] ? shownCell : state;
        }

        if (state == coveredCell) {
          row.add(new CoveredMineNode(
            this,
            flagged: false,
            posX: ix, posY: iy));
            // Mutating |hasCoveredCell| here is hacky, but convenient, same
            // goes for mutating |hasWon| below.
            hasCoveredCell = true;
        } else if (state == flaggedCell) {
          row.add(new CoveredMineNode(
            this,
            flagged: true,
            posX: ix, posY: iy));
        } else {
          row.add(new ExposedMineNode(
            state: state,
            count: count));
        }
      }
      flexRows.add(
        new Flex(
          row,
          direction: FlexDirection.horizontal,
          justifyContent: FlexJustifyContent.center,
          key: 'flex_row($iy)'
        ));
    }

    if (!hasCoveredCell) {
      // all cells uncovered. Are all mines flagged?
      if ((detectedCount == totalMineCount) && alive) {
        hasWon = true;
      }
    }

    return new Container(
      key: 'minefield',
      padding: new EdgeDims.all(10.0),
      margin: new EdgeDims.all(10.0),
      decoration: new BoxDecoration(backgroundColor: const Color(0xFF6B6B6B)),
      child: new Flex(
        flexRows,
        direction: FlexDirection.vertical,
        key: 'flxv'));
  }

  Widget buildToolBar() {
    String banner = hasWon ?
      'Awesome!!' : alive ?
        'Mine Digger [$detectedCount-$totalMineCount]': 'Kaboom! [press here]';

    return new ToolBar(
      // FIXME: Strange to have the toolbar be tapable.
      center: new Listener(
        onPointerDown: handleBannerPointerDown,
        child: new Text(banner, style: Theme.of(this.app).text.title)
      )
    );
  }

  Widget buildUI() {
    // FIXME: We need to build the board before we build the toolbar because
    // we compute the win state during build step.
    Widget board = buildBoard();
    return new Scaffold(
      toolbar: buildToolBar(),
      body: new Container(
        child: new Center(child: board),
        decoration: new BoxDecoration(backgroundColor: colors.Grey[50])
      )
    );
  }

  void handleBannerPointerDown(sky.PointerEvent event) {
    initialize();
    app.setState((){});
  }

  // User action. The user uncovers the cell which can cause losing the game.
  void probe(int x, int y) {
    if (!alive)
      return;
    if (uiState[y][x] == flaggedCell)
      return;
    // Allowed to probe.
    if (cells[y][x]) {
      // Probed on a mine --> dead!!
      uiState[y][x] = explodedCell;
      alive = false;
    } else {
      // No mine, uncover nearby if possible.
      cull(x, y);
    }
    app.setState((){});
  }

  // User action. The user is sure a mine is at this location.
  void flag(int x, int y) {
    if (uiState[y][x] == flaggedCell) {
      uiState[y][x] = coveredCell;
      --detectedCount;
    } else {
      uiState[y][x] = flaggedCell;
      ++detectedCount;
    }
    app.setState((){});
  }

  // Recursively uncovers cells whose totalMineCount is zero.
  void cull(int x, int y) {
    if ((x < 0) || (x > rows - 1))
      return;
    if ((y < 0) || (y > cols - 1))
      return;

    if (uiState[y][x] == clearedCell)
      return;
    uiState[y][x] = clearedCell;

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

Widget makeCell(Widget widget) {
  return new Container(
    padding: new EdgeDims.all(1.0),
    height: 27.0, width: 27.0,
    decoration: new BoxDecoration(backgroundColor: const Color(0xFFC0C0C0)),
    margin: new EdgeDims.all(2.0),
    child: widget);
}

Widget makeInnerCell(Widget widget) {
  return new Container(
    padding: new EdgeDims.all(1.0),
    margin: new EdgeDims.all(3.0),
    height: 17.0, width: 17.0,
    child: widget);
}

class CoveredMineNode extends Component {
  final Game game;
  final bool flagged;
  final int posX;
  final int posY;
  Stopwatch stopwatch;

  CoveredMineNode(this.game, {this.flagged, this.posX, this.posY});

  void _handlePointerDown(sky.PointerEvent event) {
    if (event.buttons == 1) {
      game.probe(posX, posY);
    } else if (event.buttons == 2) {
      game.flag(posX, posY);
    } else {
      // Touch event.
      stopwatch = new Stopwatch()..start();
    }
  }

  void _handlePointerUp(sky.PointerEvent event) {
    if (stopwatch == null)
      return;
    // Pointer down was a touch event.
    if (stopwatch.elapsedMilliseconds < 250) {
      game.probe(posX, posY);
    } else {
      // Long press flags.
      game.flag(posX, posY);
    }
    stopwatch = null;
  }

  Widget build() {
    Widget text = flagged ?
      makeInnerCell(new StyledText(elements : [Game.textStyles[5], '\u2691'])) :
      null;

    Container inner = new Container(
      margin: new EdgeDims.all(2.0),
      height: 17.0, width: 17.0,
      decoration: new BoxDecoration(backgroundColor: const Color(0xFFD9D9D9)),
      child: text);

    return makeCell(new Listener(
      child: inner,
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp));
  }
}

class ExposedMineNode extends Component {
  final int state;
  final int count;

  ExposedMineNode({this.state, this.count});

  Widget build() {
    StyledText text;
    if (state == Game.clearedCell) {
      // Uncovered cell with nearby mine count.
      if (count != 0)
        text = new StyledText(elements : [Game.textStyles[count], '$count']);
    } else {
      // Exploded mine or shown mine for 'game over'.
      int color = state == Game.explodedCell ? 3 : 0;
      text = new StyledText(elements : [Game.textStyles[color], '\u2600']);
    }

    return makeCell(makeInnerCell(text));
  }
}

class MineDiggerApp extends App {
  Game game;

  MineDiggerApp() {
    game = new Game(this);
  }

  Widget build() {
    return game.buildUI();
  }
}

void main() {
  runApp(new MineDiggerApp());
}
