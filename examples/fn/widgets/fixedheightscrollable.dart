part of widgets;

abstract class FixedHeightScrollable extends Component {

  // TODO(rafaelw): This component really shouldn't have an opinion
  // about how it is sized. The owning component should decide whether
  // it's explicitly sized or flexible or whatever...
  static Style _style = new Style('''
    overflow: hidden;
    position: relative;
    flex: 1;
    will-change: transform;'''
  );

  static Style _scrollAreaStyle = new Style('''
    position:relative;
    will-change: transform;'''
  );

  double minOffset;
  double maxOffset;

  double _scrollOffset = 0.0;
  FlingCurve _flingCurve;
  int _flingAnimationId;
  double _height = 0.0;
  double _itemHeight;

  FixedHeightScrollable({
    Object key,
    this.minOffset,
    this.maxOffset
  }) : super(key: key) {}

  List<Node> renderItems(int start, int count);

  void didMount() {
    var root = getRoot();
    var item = root.firstChild.firstChild;
    sky.ClientRect scrollRect = root.getBoundingClientRect();
    sky.ClientRect itemRect = item.getBoundingClientRect();
    assert(scrollRect.height > 0);
    assert(itemRect.height > 0);

    setState(() {
      _height = scrollRect.height;
      _itemHeight = itemRect.height;
    });
  }

  Node render() {
    var itemNumber = 0;
    var drawCount = 1;
    var transformStyle = '';

    if (_height > 0.0) {
      drawCount = (_height / _itemHeight).round() + 1;
      double alignmentDelta = -_scrollOffset % _itemHeight;
      if (alignmentDelta != 0.0) {
        alignmentDelta -= _itemHeight;
      }

      double drawStart = _scrollOffset + alignmentDelta;
      itemNumber = (drawStart / _itemHeight).floor();

      transformStyle =
          'transform: translateY(${(alignmentDelta).toStringAsFixed(2)}px)';
    }

    return new Container(
      style: _style,
      children: [
        new Container(
          style: _scrollAreaStyle,
          inlineStyle: transformStyle,
          children: renderItems(itemNumber, drawCount)
        )
      ]
    )
    ..events.listen('gestureflingstart', _handleFlingStart)
    ..events.listen('gestureflingcancel', _handleFlingCancel)
    ..events.listen('gesturescrollupdate', _handleScrollUpdate)
    ..events.listen('wheel', _handleWheel);
  }

  void didUnmount() {
    _stopFling();
  }

  bool _scrollBy(double scrollDelta) {
    var newScrollOffset = _scrollOffset + scrollDelta;
    if (minOffset != null && newScrollOffset < minOffset) {
      newScrollOffset = minOffset;
    } else if (maxOffset != null && newScrollOffset > maxOffset) {
      newScrollOffset = maxOffset;
    }
    if (newScrollOffset == _scrollOffset) {
      return false;
    }

    setState(() {
      _scrollOffset = newScrollOffset;
    });
    return true;
  }

  void _scheduleFlingUpdate() {
    _flingAnimationId = sky.window.requestAnimationFrame(_updateFling);
  }

  void _stopFling() {
    if (_flingAnimationId == null) {
      return;
    }

    sky.window.cancelAnimationFrame(_flingAnimationId);
    _flingCurve = null;
    _flingAnimationId = null;
  }

  void _updateFling(double timeStamp) {
    double scrollDelta = _flingCurve.update(timeStamp);
    if (!_scrollBy(scrollDelta))
      return _stopFling();
    _scheduleFlingUpdate();
  }

  void _handleScrollUpdate(sky.GestureEvent event) {
    _scrollBy(-event.dy);
  }

  void _handleFlingStart(sky.GestureEvent event) {
    setState(() {
      _flingCurve = new FlingCurve(-event.velocityY, event.timeStamp);
      _scheduleFlingUpdate();
    });
  }

  void _handleFlingCancel(sky.GestureEvent event) {
    _stopFling();
  }

  void _handleWheel(sky.WheelEvent event) {
    _scrollBy(-event.offsetY);
  }
}
