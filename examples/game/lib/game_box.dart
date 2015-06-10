part of game;

const double _steeringThreshold = 20.0;
const double _steeringMax = 50.0;

class GameBox extends SpriteBox {

  GameBox(GameWorld game) : super(game, SpriteBoxTransformMode.letterbox);

  GameWorld get _gameWorld => this.rootNode;

  // Handle pointers
  int _firstPointer = -1;
  int _secondPointer = -1;
  Vector2 _firstPointerDownPos;

  void handleEvent(Event event, BoxHitTestEntry entry) {
    if (event is PointerEvent) {
      Vector2 pointerPos = new Vector2(event.x, event.y);
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
            _gameWorld.controlThrust(1.0);
          }
          else {
            // There is a pointer used for steering, let's fire instead
            _gameWorld.controlFire();
          }
          break;
        case 'pointermove':
          if (pointer == _firstPointer) {
            // Handle turning control
            double deltaX = pointerPos[0] - _firstPointerDownPos[0];
            if (deltaX > _steeringThreshold || deltaX < -_steeringThreshold) {
              double turnForce = (deltaX - _steeringThreshold)/(_steeringMax - _steeringThreshold);
              if (turnForce > 1.0) turnForce = 1.0;
              if (turnForce < -1.0) turnForce = -1.0;
              _gameWorld.controlSteering(turnForce);
              print("steering: $turnForce");
            }
          }
          break;
        case 'pointerup':
        case 'pointercancel':
          if (pointer == _firstPointer) {
            // Un-assign the first pointer
            _firstPointer = -1;
            _firstPointerDownPos = null;
            _gameWorld.controlSteering(null);
          }
          else if (pointer == _secondPointer) {
            _secondPointer = -1;
            _gameWorld.controlThrust(null);
          }
          break;
        default:
          break;
      }
    }
  }

}
