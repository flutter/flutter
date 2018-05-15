import 'package:flutter/foundation.dart';
import 'package:flutter/src/painting/image_provider.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/image.dart';


///
class ImageBehavior extends StatefulWidget {
    
  ///
  const ImageBehavior({
    Key key,
    this.delegate = const ImageBehaviorDelegate(),
    this.precache = const <ImageProvider<Object>>[],
    @required this.child,
  }) : assert(delegate != null),
       super(key: key);

  ///
  final ImageBehaviorDelegate delegate;

  ///
  final Widget child;

  ///
  final List<ImageProvider> precache;

  ///
  static ImageBehaviorDelegate of(BuildContext context) {
    final _InheritedImageBehavior behavior = context.inheritFromWidgetOfExactType(_InheritedImageBehavior);
    return behavior?.delegate ?? const ImageBehaviorDelegate();
  }

  @override
  State<ImageBehavior> createState() => new _ImageBehaviorState();
}

class _ImageBehaviorState extends State<ImageBehavior> {
  @override
  void initState() {
    _precacheImages();
    super.initState();
  }

  @override
  void didUpdateWidget(ImageBehavior oldWidget) {
    if (!identical(oldWidget.precache, widget.precache)) {
      _precacheImages();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.delegate.dispose();
    super.dispose();
  }

  void _precacheImages() {
    final ImageConfiguration configuration = createLocalImageConfiguration(context)
      .copyWith(behaviorDelegate: widget.delegate);
    for (ImageProvider<Object> provider in widget.precache)
      provider.resolve(configuration);
  }

  @override
  Widget build(BuildContext context) {
    return new _InheritedImageBehavior(
      child: widget.child,
      delegate: widget.delegate
    );
  }
}

/// 
class _InheritedImageBehavior extends InheritedWidget {
  
  ///
  const _InheritedImageBehavior({
    Key key,
    @required this.delegate,
    @required Widget child,
  }) : super(key: key, child: child);

  ///
  final ImageBehaviorDelegate delegate;

  @override
  bool updateShouldNotify(covariant _InheritedImageBehavior oldWidget) {
    return oldWidget.delegate.runtimeType != delegate.runtimeType;
  }
}