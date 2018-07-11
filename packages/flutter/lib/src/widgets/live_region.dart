import 'package:flutter/rendering.dart';
import 'package:flutter/src/widgets/framework.dart';


class LiveRegion extends SingleChildRenderObjectWidget {
  const LiveRegion({Key key, Widget child, this.duration})
    : assert(duration != null),
      assert(child != null),
      super(key: key, child: child);

  final Duration duration;

  @override
  RenderLiveRegion createRenderObject(BuildContext context) {
    return new RenderLiveRegion(duration);
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderLiveRegion renderObject) {
    renderObject.duration = duration;
  }
}

class RenderLiveRegion extends RenderProxyBox {
  RenderLiveRegion(Duration duration, [RenderBox child])
    : assert(duration != null),
      _duration = duration,
      super(child);

  Duration _lastUpdate;
  Duration _duration;
  Duration get duration => _duration;
  set duration(Duration value) {
    if (_duration == value)
      return;
    _duration = value;
    markNeedsSemanticsUpdate();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.explicitChildNodes = false;
    config.isSemanticBoundary = true;
    config.liveRegion = true;
  }
}