import 'dart:io';
import 'dart:math' show min;

import 'package:dart_console/dart_console.dart';

const kiloVersion = '0.0.3';
const kiloTabStopLength = 4;

//
// GLOBAL VARIABLES
//

final console = Console();

String editedFilename = '';
bool isFileDirty = false;

// We keep two copies of the file contents, as follows:
//
// fileRows represents the actual contents of the document
//
// renderRows represents what we'll render on screen. This may be different to
// the actual contents of the file. For example, tabs are rendered as a series
// of spaces even though they are only one character; control characters may
// be shown in some form in the future.
List<String> fileRows = [];
List<String> renderRows = [];

// Cursor location relative to file (not the screen)
int cursorCol = 0, cursorRow = 0;

// Also store cursor column position relative to the rendered row
int cursorRenderCol = 0;

// The row in the file that is currently at the top of the screen
int screenFileRowOffset = 0;
// The column in the row that is currently on the left of the screen
int screenRowColOffset = 0;

// Allow lines for the status bar and message bar
final editorWindowHeight = console.windowHeight - 2;
final editorWindowWidth = console.windowWidth;

// Index of the row last find match was on, or -1 if no match
int findLastMatchRow = -1;

// Current search direction
enum FindDirection { forwards, backwards }
FindDirection findDirection = FindDirection.forwards;

String messageText = '';
late DateTime messageTimestamp;

void initEditor() {
  isFileDirty = false;
}

void crash(String message) {
  console.clearScreen();
  console.resetCursorPosition();
  console.rawMode = false;
  console.write(message);
  exit(1);
}

String truncateString(String text, int length) =>
    length < text.length ? text.substring(0, length) : text;

//
// EDITOR OPERATIONS
//
void editorInsertChar(String char) {
  if (cursorRow == fileRows.length) {
    fileRows.add(char);
    renderRows.add(char);
  } else {
    fileRows[cursorRow] = fileRows[cursorRow].substring(0, cursorCol) +
        char +
        fileRows[cursorRow].substring(cursorCol);
  }
  editorUpdateRenderRow(cursorRow);
  cursorCol++;
  isFileDirty = true;
}

void editorBackspaceChar() {
  // If we're past the end of the file, then there's nothing to delete
  if (cursorRow == fileRows.length) return;

  // Nothing to do if we're at the first character of the file
  if (cursorCol == 0 && cursorRow == 0) return;

  if (cursorCol > 0) {
    fileRows[cursorRow] = fileRows[cursorRow].substring(0, cursorCol - 1) +
        fileRows[cursorRow].substring(cursorCol);
    editorUpdateRenderRow(cursorRow);
    cursorCol--;
  } else {
    // delete the carriage return by appending the current line to the previous
    // one and then removing the current line altogether.
    cursorCol = fileRows[cursorRow - 1].length;
    fileRows[cursorRow - 1] += fileRows[cursorRow];
    editorUpdateRenderRow(cursorRow - 1);
    fileRows.removeAt(cursorRow);
    renderRows.removeAt(cursorRow);
    cursorRow--;
  }
  isFileDirty = true;
}

void editorInsertNewline() {
  if (cursorCol == 0) {
    fileRows.insert(cursorRow, '');
    renderRows.insert(cursorRow, '');
  } else {
    fileRows.insert(cursorRow + 1, fileRows[cursorRow].substring(cursorCol));
    fileRows[cursorRow] = fileRows[cursorRow].substring(0, cursorCol);

    renderRows.insert(cursorRow + 1, '');
    editorUpdateRenderRow(cursorRow);
    editorUpdateRenderRow(cursorRow + 1);
  }
  cursorRow++;
  cursorCol = 0;
}

void editorFindCallback(String query, Key key) {
  if (key.controlChar == ControlCharacter.enter ||
      key.controlChar == ControlCharacter.escape) {
    findLastMatchRow = -1;
    findDirection = FindDirection.forwards;
    return;
  } else if (key.controlChar == ControlCharacter.arrowRight ||
      key.controlChar == ControlCharacter.arrowDown) {
    findDirection = FindDirection.forwards;
  } else if (key.controlChar == ControlCharacter.arrowLeft ||
      key.controlChar == ControlCharacter.arrowUp) {
    findDirection = FindDirection.backwards;
  } else {
    findLastMatchRow = -1;
    findDirection = FindDirection.forwards;
  }

  if (findLastMatchRow == -1) findDirection = FindDirection.forwards;

  var currentRow = findLastMatchRow;
  if (query.isNotEmpty) {
    // we loop through all the rows, rotating back to the beginning/end as
    // necessary
    for (var i = 0; i < renderRows.length; i++) {
      if (findDirection == FindDirection.forwards) {
        currentRow++;
      } else {
        currentRow--;
      }

      if (currentRow == -1) {
        currentRow = fileRows.length - 1;
      } else if (currentRow == fileRows.length) {
        currentRow = 0;
      }

      if (renderRows[currentRow].contains(query)) {
        findLastMatchRow = currentRow;
        cursorRow = currentRow;
        cursorCol =
            getFileCol(currentRow, renderRows[currentRow].indexOf(query));
        screenFileRowOffset = fileRows.length;
        editorSetStatusMessage(
            'Search (ESC to cancel, use arrows for prev/next): $query');
        editorRefreshScreen();
        break;
      }
    }
  }
}

void editorFind() {
  final savedCursorCol = cursorCol;
  final savedCursorRow = cursorRow;
  final savedScreenFileRowOffset = screenFileRowOffset;
  final savedScreenRowColOffset = screenRowColOffset;

  final query = editorPrompt(
      'Search (ESC to cancel, use arrows for prev/next): ', editorFindCallback);

  if (query == null) {
    // Escape pressed
    cursorCol = savedCursorCol;
    cursorRow = savedCursorRow;
    screenFileRowOffset = savedScreenFileRowOffset;
    screenRowColOffset = savedScreenRowColOffset;
  }
}

//
// FILE I/O
//
void editorOpen(String filename) {
  final file = File(filename);
  try {
    fileRows = file.readAsLinesSync();
  } on FileSystemException catch (e) {
    editorSetStatusMessage('Error opening file: $e');
    return;
  }

  for (var rowIndex = 0; rowIndex < fileRows.length; rowIndex++) {
    renderRows.add('');
    editorUpdateRenderRow(rowIndex);
  }

  assert(fileRows.length == renderRows.length);

  isFileDirty = false;
}

void editorSave() {
  if (editedFilename.isEmpty) {
    final saveFilename = editorPrompt('Save as: ');
    if (saveFilename == null) {
      editorSetStatusMessage('Save aborted.');
      return;
    } else {
      editedFilename = saveFilename;
    }
  }

  // TODO: This is hopelessly naive, as with kilo.c. We should write to a
  //    temporary file and rename to ensure that we have written successfully.
  final file = File(editedFilename);
  final fileContents = '${fileRows.join('\n')}\n';
  file.writeAsStringSync(fileContents);

  isFileDirty = false;

  editorSetStatusMessage('${fileContents.length} bytes written to disk.');
}

void editorQuit() {
  if (isFileDirty) {
    editorSetStatusMessage('File is unsaved. Quit anyway (y or n)?');
    editorRefreshScreen();
    final response = console.readKey();
    if (response.char != 'y' && response.char != 'Y') {
      {
        editorSetStatusMessage('');
        return;
      }
    }
  }
  console.clearScreen();
  console.resetCursorPosition();
  console.rawMode = false;
  exit(0);
}

//
// RENDERING OPERATIONS
//

// Takes a column in a given row of the file and converts it to the rendered
// column. For example, if the file contains \t\tFoo and tab stops are
// configured to display as eight spaces, the 'F' should display as rendered
// column 16 even though it is only the third character in the file.
int getRenderedCol(int fileRow, int fileCol) {
  var col = 0;

  if (fileRow >= fileRows.length) return 0;

  final rowText = fileRows[fileRow];
  for (var i = 0; i < fileCol; i++) {
    if (rowText[i] == '\t') {
      col += (kiloTabStopLength - 1) - (col % kiloTabStopLength);
    }
    col++;
  }
  return col;
}

// Inversion of the getRenderedCol method. Converts a rendered column index
// into its corresponding position in the file.
int getFileCol(int row, int renderCol) {
  var currentRenderCol = 0;
  int fileCol;
  final rowText = fileRows[row];
  for (fileCol = 0; fileCol < rowText.length; fileCol++) {
    if (rowText[fileCol] == '\t') {
      currentRenderCol +=
          (kiloTabStopLength - 1) - (currentRenderCol % kiloTabStopLength);
    }
    currentRenderCol++;

    if (currentRenderCol > renderCol) return fileCol;
  }
  return fileCol;
}

void editorUpdateRenderRow(int rowIndex) {
  assert(renderRows.length == fileRows.length);

  var renderBuffer = '';
  final fileRow = fileRows[rowIndex];

  for (var fileCol = 0; fileCol < fileRow.length; fileCol++) {
    if (fileRow[fileCol] == '\t') {
      // Add at least one space for the tab stop, plus as many more as needed to
      // get to the next tab stop
      renderBuffer += ' ';
      while (renderBuffer.length % kiloTabStopLength != 0) {
        // ignore: use_string_buffers
        renderBuffer += ' ';
      }
    } else {
      renderBuffer += fileRow[fileCol];
    }
    renderRows[rowIndex] = renderBuffer;
  }
}

void editorScroll() {
  cursorRenderCol = 0;

  if (cursorRow < fileRows.length) {
    cursorRenderCol = getRenderedCol(cursorRow, cursorCol);
  }

  if (cursorRow < screenFileRowOffset) {
    screenFileRowOffset = cursorRow;
  }

  if (cursorRow >= screenFileRowOffset + editorWindowHeight) {
    screenFileRowOffset = cursorRow - editorWindowHeight + 1;
  }

  if (cursorRenderCol < screenRowColOffset) {
    screenRowColOffset = cursorRenderCol;
  }

  if (cursorRenderCol >= screenRowColOffset + editorWindowWidth) {
    screenRowColOffset = cursorRenderCol - editorWindowWidth + 1;
  }
}

void editorDrawRows() {
  final screenBuffer = StringBuffer();

  for (var screenRow = 0; screenRow < editorWindowHeight; screenRow++) {
    // fileRow is the row of the file we want to print to screenRow
    final fileRow = screenRow + screenFileRowOffset;

    // If we're beyond the text buffer, print tilde in column 0
    if (fileRow >= fileRows.length) {
      // Show a welcome message
      if (fileRows.isEmpty && (screenRow == (editorWindowHeight / 3).round())) {
        // Print the welcome message centered a third of the way down the screen
        final welcomeMessage = truncateString(
            'Kilo editor -- version $kiloVersion', editorWindowWidth);
        var padding = ((editorWindowWidth - welcomeMessage.length) / 2).round();
        if (padding > 0) {
          screenBuffer.write('~');
          padding--;
        }
        while (padding-- > 0) {
          screenBuffer.write(' ');
        }
        screenBuffer.write(welcomeMessage);
      } else {
        screenBuffer.write('~');
      }
    }

    // Otherwise print the onscreen portion of the current file row,
    // trimmed if necessary
    else {
      if (renderRows[fileRow].length - screenRowColOffset > 0) {
        screenBuffer.write(truncateString(
            renderRows[fileRow].substring(screenRowColOffset),
            editorWindowWidth));
      }
    }

    screenBuffer.write(console.newLine);
  }
  console.write(screenBuffer.toString());
}

void editorDrawStatusBar() {
  console.setTextStyle(inverted: true);

  // TODO: Displayed filename should not include path.
  var leftString =
      '${truncateString(editedFilename.isEmpty ? "[No Name]" : editedFilename, (editorWindowWidth / 2).ceil())}'
      ' - ${fileRows.length} lines';
  if (isFileDirty) leftString += ' (modified)';
  final rightString = '${cursorRow + 1}/${fileRows.length}';
  final padding = editorWindowWidth - leftString.length - rightString.length;

  console.write('$leftString'
      '${" " * padding}'
      '$rightString');

  console.resetColorAttributes();
  console.writeLine();
}

void editorDrawMessageBar() {
  if (DateTime.now().difference(messageTimestamp) <
      const Duration(seconds: 5)) {
    console.write(truncateString(messageText, editorWindowWidth)
        .padRight(editorWindowWidth));
  }
}

void editorRefreshScreen() {
  editorScroll();

  console.hideCursor();
  console.clearScreen();

  editorDrawRows();
  editorDrawStatusBar();
  editorDrawMessageBar();

  console.cursorPosition = Coordinate(
      cursorRow - screenFileRowOffset, cursorRenderCol - screenRowColOffset);
  console.showCursor();
}

void editorSetStatusMessage(String message) {
  messageText = message;
  messageTimestamp = DateTime.now();
}

String? editorPrompt(String message,
    [Function(String text, Key lastPressed)? callback]) {
  final originalCursorRow = cursorRow;

  editorSetStatusMessage(message);
  editorRefreshScreen();

  console.cursorPosition = Coordinate(console.windowHeight - 1, message.length);

  final response = console.readLine(cancelOnEscape: true, callback: callback);
  cursorRow = originalCursorRow;
  editorSetStatusMessage('');

  return response;
}

//
// INPUT OPERATIONS
//
void editorMoveCursor(ControlCharacter key) {
  switch (key) {
    case ControlCharacter.arrowLeft:
      if (cursorCol != 0) {
        cursorCol--;
      } else if (cursorRow > 0) {
        cursorRow--;
        cursorCol = fileRows[cursorRow].length;
      }
      break;
    case ControlCharacter.arrowRight:
      if (cursorRow < fileRows.length) {
        if (cursorCol < fileRows[cursorRow].length) {
          cursorCol++;
        } else if (cursorCol == fileRows[cursorRow].length) {
          cursorCol = 0;
          cursorRow++;
        }
      }
      break;
    case ControlCharacter.arrowUp:
      if (cursorRow != 0) cursorRow--;
      break;
    case ControlCharacter.arrowDown:
      if (cursorRow < fileRows.length) cursorRow++;
      break;
    case ControlCharacter.pageUp:
      cursorRow = screenFileRowOffset;
      for (var i = 0; i < editorWindowHeight; i++) {
        editorMoveCursor(ControlCharacter.arrowUp);
      }
      break;
    case ControlCharacter.pageDown:
      cursorRow = screenFileRowOffset + editorWindowHeight - 1;
      for (var i = 0; i < editorWindowHeight; i++) {
        editorMoveCursor(ControlCharacter.arrowDown);
      }
      break;
    case ControlCharacter.home:
      cursorCol = 0;
      break;
    case ControlCharacter.end:
      if (cursorRow < fileRows.length) {
        cursorCol = fileRows[cursorRow].length;
      }
      break;
    default:
  }

  if (cursorRow < fileRows.length) {
    cursorCol = min(cursorCol, fileRows[cursorRow].length);
  }
}

void editorProcessKeypress() {
  final key = console.readKey();

  if (key.isControl) {
    switch (key.controlChar) {
      case ControlCharacter.ctrlQ:
        editorQuit();
        break;
      case ControlCharacter.ctrlS:
        editorSave();
        break;
      case ControlCharacter.ctrlF:
        editorFind();
        break;
      case ControlCharacter.backspace:
      case ControlCharacter.ctrlH:
        editorBackspaceChar();
        break;
      case ControlCharacter.delete:
        editorMoveCursor(ControlCharacter.arrowRight);
        editorBackspaceChar();
        break;
      case ControlCharacter.enter:
        editorInsertNewline();
        break;
      case ControlCharacter.arrowLeft:
      case ControlCharacter.arrowUp:
      case ControlCharacter.arrowRight:
      case ControlCharacter.arrowDown:
      case ControlCharacter.pageUp:
      case ControlCharacter.pageDown:
      case ControlCharacter.home:
      case ControlCharacter.end:
        editorMoveCursor(key.controlChar);
        break;
      case ControlCharacter.ctrlA:
        editorMoveCursor(ControlCharacter.home);
        break;
      case ControlCharacter.ctrlE:
        editorMoveCursor(ControlCharacter.end);
        break;
      default:
    }
  } else {
    editorInsertChar(key.char);
  }
}

//
// ENTRY POINT
//

void main(List<String> arguments) {
  try {
    console.rawMode = true;
    initEditor();
    if (arguments.isNotEmpty) {
      editedFilename = arguments[0];
      editorOpen(editedFilename);
    }

    editorSetStatusMessage(
        'HELP: Ctrl-S = save | Ctrl-Q = quit | Ctrl-F = find');

    while (true) {
      editorRefreshScreen();
      editorProcessKeypress();
    }
  } catch (exception) {
    // Make sure raw mode gets disabled if we hit some unrelated problem
    console.rawMode = false;
    rethrow;
  }
}
