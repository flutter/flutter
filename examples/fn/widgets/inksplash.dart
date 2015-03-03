part of widgets;

const double _kSplashSize = 400.0;
const double _kSplashDuration = 500.0;

class SplashAnimation {
  AnimationGenerator _animation;
  double _offsetX;
  double _offsetY;

  Stream<String> _styleChanged;

  Stream<String> get onStyleChanged => _styleChanged;

  void cancel() => _animation.cancel();

  SplashAnimation(sky.ClientRect rect, double x, double y,
                  { Function onDone })
      : _offsetX = x - rect.left,
        _offsetY = y - rect.top {

    _animation = new AnimationGenerator(_kSplashDuration,
        end: _kSplashSize, curve: easeOut, onDone: onDone);

    _styleChanged = _animation.onTick.map((p) => '''
      top: ${_offsetY - p/2}px;
      left: ${_offsetX - p/2}px;
      width: ${p}px;
      height: ${p}px;
      border-radius: ${p}px;
      opacity: ${1.0 - (p / _kSplashSize)};
    ''');
  }
}

class InkSplash extends Component {

  Stream<String> onStyleChanged;

  static Style _style = new Style('''
    position: absolute;
    pointer-events: none;
    overflow: hidden;
    top: 0;
    left: 0;
    bottom: 0;
    right: 0;
  ''');

  static Style _splashStyle = new Style('''
    position: absolute;
    background-color: rgba(0, 0, 0, 0.4);
    border-radius: 0;
    top: 0;
    left: 0;
    height: 0;
    width: 0;
  ''');

  double _offsetX;
  double _offsetY;
  String _inlineStyle;

  InkSplash(Stream<String> onStyleChanged)
    : onStyleChanged = onStyleChanged,
      super(stateful: true, key: onStyleChanged.hashCode);

  bool _listening = false;

  void _ensureListening() {
    if (_listening)
      return;

    _listening = true;

    onStyleChanged.listen((style) {
      setState(() {
        _inlineStyle = style;
      });
    });
  }

  Node render() {
    _ensureListening();

    return new Container(
      style: _style,
      children: [
        new Container(
          inlineStyle: _inlineStyle,
          style: _splashStyle
        )
      ]
    );
  }
}
