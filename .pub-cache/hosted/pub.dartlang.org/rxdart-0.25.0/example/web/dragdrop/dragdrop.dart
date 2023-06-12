import 'dart:html';

import 'package:rxdart/rxdart.dart';

// Side note: To maintain readability, this example was not formatted using dart_fmt.

void main() {
  final dragTarget = querySelector('#dragTarget');
  final mouseUp = document.onMouseUp;
  final mouseMove = document.onMouseMove;
  final mouseDown = document.onMouseDown;

  mouseDown
      // Use map() to calculate the left and top properties on mouseDown
      .map((event) => Point<num>(event.client.x - dragTarget.offset.left,
          event.client.y - dragTarget.offset.top))
      // Use switchMap() to get the mouse position on each mouseMove
      .switchMap((startPosition) {
    return mouseMove
        // Use map() to calculate the left and top properties on each mouseMove
        .map((event) => Point<num>(
            event.client.x - startPosition.x, event.client.y - startPosition.y))
        // Use takeUntil() to stop calculations when a mouseUp occurs
        .takeUntil(mouseUp);
  })
      // Use listen() to update the position of the dragTarget
      .listen((position) {
    dragTarget.style.left = '${position.x}px';
    dragTarget.style.top = '${position.y}px';
  });
}
