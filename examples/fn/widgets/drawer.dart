part of widgets;

const double _kWidth = 256.0;
const double _kMinFlingVelocity = 0.4;
const double _kMinAnimationDurationMS = 246.0;
const double _kMaxAnimationDurationMS = 600.0;
const Cubic _kAnimationCurve = easeOut;

class DrawerAnimation {

  Stream<double> get onPositionChanged => _controller.stream;

  StreamController _controller;
  AnimationGenerator _animation;
  double _position;
  bool get _isAnimating => _animation != null;
  bool get _isMostlyClosed => _position <= -_kWidth / 2;

  DrawerAnimation() {
    _controller = new StreamController(sync: true);
    _setPosition(-_kWidth);
  }

  void toggle(_) => _isMostlyClosed ? _open() : _close();

  void handleMaskTap(_) => _close();

  void handlePointerDown(_) => _cancelAnimation();

  void handlePointerMove(sky.PointerEvent event) {
    assert(_animation == null);
    _setPosition(_position + event.dx);
  }

  void handlePointerUp(_) {
    if (!_isAnimating)
      _settle();
  }

  void handlePointerCancel(_) {
    if (!_isAnimating)
      _settle();
  }

  void _open() => _animateToPosition(0.0);

  void _close() => _animateToPosition(-_kWidth);

  void _settle() => _isMostlyClosed ? _close() : _open();

  void _setPosition(double value) {
    _position = math.min(0.0, math.max(value, -_kWidth));
    _controller.add(_position);
  }

  void _cancelAnimation() {
    if (_animation != null) {
      _animation.cancel();
      _animation = null;
    }
  }

  void _animate(double duration, double begin, double end, Curve curve) {
    _cancelAnimation();

    _animation = new AnimationGenerator(duration, begin: begin, end: end,
        curve: curve);

    _animation.onTick.listen(_setPosition, onDone: () {
      _animation = null;
    });
  }

  void _animateToPosition(double targetPosition) {
    double distance = (targetPosition - _position).abs();
    double duration = math.max(
        _kMinAnimationDurationMS,
        _kMaxAnimationDurationMS * distance / _kWidth);

    _animate(duration, _position, targetPosition, _kAnimationCurve);
  }

  void handleFlingStart(event) {
    double direction = event.velocityX.sign;
    double velocityX = event.velocityX.abs() / 1000;
    if (velocityX < _kMinFlingVelocity)
      return;

    double targetPosition = direction < 0.0 ? -_kWidth : 0.0;
    double distance = (targetPosition - _position).abs();
    double duration = distance / velocityX;

    _animate(duration, _position, targetPosition, linear);
  }
}

class Drawer extends Component {

  static Style _style = new Style('''
    position: absolute;
    z-index: 2;
    top: 0;
    left: 0;
    bottom: 0;
    right: 0;
    box-shadow: 0 10px 20px rgba(0,0,0,0.19), 0 6px 6px rgba(0,0,0,0.23);'''
  );

  static Style _maskStyle = new Style('''
    background-color: black;
    will-change: opacity;
    position: absolute;
    top: 0;
    left: 0;
    bottom: 0;
    right: 0;'''
  );

  static Style _contentStyle = new Style('''
    background-color: #FAFAFA;
    will-change: transform;
    position: absolute;
    width: 256px;
    top: 0;
    left: 0;
    bottom: 0;'''
  );

  Stream<double> onPositionChanged;
  sky.EventListener handleMaskFling;
  sky.EventListener handleMaskTap;
  sky.EventListener handlePointerCancel;
  sky.EventListener handlePointerDown;
  sky.EventListener handlePointerMove;
  sky.EventListener handlePointerUp;
  List<Node> children;

  Drawer({
    Object key,
    this.onPositionChanged,
    this.handleMaskFling,
    this.handleMaskTap,
    this.handlePointerCancel,
    this.handlePointerDown,
    this.handlePointerMove,
    this.handlePointerUp,
    this.children
  }) : super(key: key);

  double _position = -_kWidth;

  bool _listening = false;

  void _ensureListening() {
    if (_listening)
      return;

    _listening = true;
    onPositionChanged.listen((position) {
      setState(() {
        _position = position;
      });
    });
  }

  Node render() {
    _ensureListening();

    bool isClosed = _position <= -_kWidth;
    String inlineStyle = 'display: ${isClosed ? 'none' : ''}';
    String maskInlineStyle = 'opacity: ${(_position / _kWidth + 1) * 0.25}';
    String contentInlineStyle = 'transform: translateX(${_position}px)';

    return new Container(
      style: _style,
      inlineStyle: inlineStyle,
      onPointerDown: handlePointerDown,
      onPointerMove: handlePointerMove,
      onPointerUp: handlePointerUp,
      onPointerCancel: handlePointerCancel,

      children: [
        new Container(
          key: 'Mask',
          style: _maskStyle,
          inlineStyle: maskInlineStyle,
          onGestureTap: handleMaskTap,
          onFlingStart: handleMaskFling
        ),
        new Container(
          key: 'Content',
          style: _contentStyle,
          inlineStyle: contentInlineStyle,
          children: children
        )
      ]
    );
  }
}
