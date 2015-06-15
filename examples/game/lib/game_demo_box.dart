part of game;

const double _steeringThreshold = 0.0;
const double _steeringMax = 150.0;

class GameDemoBox extends SpriteBox {

  GameDemoBox(GameDemoWorld game) : super(game, SpriteBoxTransformMode.letterbox);

  GameDemoWorld get _gameWorld => this.rootNode;

  // Handle pointers
  int _firstPointer = -1;
  int _secondPointer = -1;
  Point _firstPointerDownPos;

  void handleEvent(Event event, BoxHitTestEntry entry) {
    if (event is PointerEvent) {
      Point pointerPos = new Point(event.x, event.y);
      int pointer = event.pointer;

      switch (event.type) {
        case 'pointerdown':
          if (_firstPointer == -1) {
            // Assign the first pointer
            _firstPointer = pointer;
            _firstPointerDownPos = pointerPos;
          }
          else if (_secondPointer == -1) {
            // Assign second pointer
            _secondPointer = pointer;
            _gameWorld.controlFire();
          }
          else {
            // There is a pointer used for steering, let's fire instead
            _gameWorld.controlFire();
          }
          break;
        case 'pointermove':
          if (pointer == _firstPointer) {
            // Handle turning control
            double joystickX = 0.0;
            double deltaX = pointerPos.x - _firstPointerDownPos.x;
            if (deltaX > _steeringThreshold || deltaX < -_steeringThreshold) {
              joystickX = (deltaX - _steeringThreshold)/(_steeringMax - _steeringThreshold);
              if (joystickX > 1.0) joystickX = 1.0;
              if (joystickX < -1.0) joystickX = -1.0;
            }

            double joystickY = 0.0;
            double deltaY = pointerPos.y - _firstPointerDownPos.y;
            if (deltaY > _steeringThreshold || deltaY < -_steeringThreshold) {
              joystickY = (deltaY - _steeringThreshold)/(_steeringMax - _steeringThreshold);
              if (joystickY > 1.0) joystickY = 1.0;
              if (joystickY < -1.0) joystickY = -1.0;
            }

            _gameWorld.controlSteering(joystickX, joystickY);
          }
          break;
        case 'pointerup':
        case 'pointercancel':
          if (pointer == _firstPointer) {
            // Un-assign the first pointer
            _firstPointer = -1;
            _firstPointerDownPos = null;
            _gameWorld.controlSteering(0.0, 0.0);
          }
          else if (pointer == _secondPointer) {
            _secondPointer = -1;
            _gameWorld.controlFire();
          }
          break;
        default:
          break;
      }
    }
  }

}
