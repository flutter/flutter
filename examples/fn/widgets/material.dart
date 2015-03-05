part of widgets;

abstract class MaterialComponent extends Component {

  static const _splashesKey = const Object();

  static Style _style = new Style('''
    transform: translateX(0);
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0'''
  );

  LinkedHashSet<SplashAnimation> _splashes;

  MaterialComponent({ Object key }) : super(key: key);

  Node render() {
    List<Node> children = [];

    if (_splashes != null) {
      children.addAll(_splashes.map((s) => new InkSplash(s.onStyleChanged)));
    }

    return new Container(
      style: _style,
      children: children,
      key: _splashesKey
    )..events.listen('gesturescrollstart', _cancelSplashes)
     ..events.listen('wheel', _cancelSplashes)
     ..events.listen('pointerdown', _startSplash);
  }

  sky.ClientRect _getBoundingRect() => getRoot().getBoundingClientRect();

  void _startSplash(sky.Event event) {
    setState(() {
      if (_splashes == null) {
        _splashes = new LinkedHashSet<SplashAnimation>();
      }

      var splash;
      splash = new SplashAnimation(_getBoundingRect(), event.x, event.y,
                                   onDone: () { _splashDone(splash); });

      _splashes.add(splash);
    });
  }

  void _cancelSplashes(sky.Event event) {
    if (_splashes == null) {
      return;
    }

    setState(() {
      var splashes = _splashes;
      _splashes = null;
      splashes.forEach((s) { s.cancel(); });
    });
  }

  void willUnmount() {
    _cancelSplashes(null);
  }

  void _splashDone(SplashAnimation splash) {
    if (_splashes == null) {
      return;
    }

    setState(() {
      _splashes.remove(splash);
      if (_splashes.length == 0) {
        _splashes = null;
      }
    });
  }
}
