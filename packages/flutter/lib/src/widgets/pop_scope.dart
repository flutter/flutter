import 'framework.dart';
import 'navigator.dart';
import 'routes.dart';

class PopScope extends StatefulWidget {
  const PopScope({
    Key? key,
    required this.child,
    required this.onPop,
  })  : assert(child != null),
        super(key: key);

  final Widget child;

  final VoidCallback? onPop;

  @override
  State<PopScope> createState() => _PopScopeState();
}

class _PopScopeState extends State<PopScope> {
  ModalRoute<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.onPop != null) {
      _route?.removeScopedPopCallback(widget.onPop!);
    }
    _route = ModalRoute.of(context);
    if (widget.onPop != null) {
      _route?.addScopedPopCallback(widget.onPop!);
    }
  }

  @override
  void didUpdateWidget(PopScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(_route == ModalRoute.of(context));
    if (widget.onPop != oldWidget.onPop && _route != null) {
      if (oldWidget.onPop != null) {
        _route!.removeScopedPopCallback(oldWidget.onPop!);
      }
      if (widget.onPop != null) {
        _route!.addScopedPopCallback(widget.onPop!);
      }
    }
  }

  @override
  void dispose() {
    if (widget.onPop != null) {
      _route?.removeScopedPopCallback(widget.onPop!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
