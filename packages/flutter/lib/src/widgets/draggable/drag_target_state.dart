import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter/src/widgets/framework.dart';

import 'drag_avatar.dart';
import 'drag_target.dart';

/// State for a `DragTarget`
class DragTargetState<T extends Object> extends State<DragTarget<T>> {
  final List<DragAvatar<Object>> _candidateAvatars = <DragAvatar<Object>>[];
  final List<DragAvatar<Object>> _rejectedAvatars = <DragAvatar<Object>>[];

  // On non-web platforms, checks if data Object is equal to type[T] or subtype of [T].
  // On web, it does the same, but requires a check for ints and doubles
  // because dart doubles and ints are backed by the same kind of object on web.
  // JavaScript does not support integers.
  bool isExpectedDataType(Object? data, Type type) {
    if (kIsWeb && ((type == int && T == double) || (type == double && T == int)))
      return false;
    return data is T?;
  }

  bool didEnter(DragAvatar<Object> avatar) {
    assert(!_candidateAvatars.contains(avatar));
    assert(!_rejectedAvatars.contains(avatar));
    if (widget.onWillAccept == null || widget.onWillAccept!(avatar.data as T?)) {
      setState(() {
        _candidateAvatars.add(avatar);
      });
      return true;
    } else {
      setState(() {
        _rejectedAvatars.add(avatar);
      });
      return false;
    }
  }

  void didLeave(DragAvatar<Object> avatar) {
    assert(_candidateAvatars.contains(avatar) || _rejectedAvatars.contains(avatar));
    if (!mounted)
      return;
    setState(() {
      _candidateAvatars.remove(avatar);
      _rejectedAvatars.remove(avatar);
    });
    if (widget.onLeave != null)
      widget.onLeave!(avatar.data as T?);
  }

  void didDrop(DragAvatar<Object> avatar) {
    assert(_candidateAvatars.contains(avatar));
    if (!mounted)
      return;
    setState(() {
      _candidateAvatars.remove(avatar);
    });
    if (widget.onAccept != null)
      widget.onAccept!(avatar.data! as T);
    if (widget.onAcceptWithDetails != null)
      widget.onAcceptWithDetails!(DragTargetDetails<T>(data: avatar.data! as T, offset: avatar._lastOffset!));
  }

  void didMove(DragAvatar<Object> avatar) {
    if (!mounted)
      return;
    if (widget.onMove != null)
      widget.onMove!(DragTargetDetails<T>(data: avatar.data! as T, offset: avatar._lastOffset!));
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.builder != null);
    return MetaData(
      metaData: this,
      behavior: widget.hitTestBehavior,
      child: widget.builder(context, _mapAvatarsToData<T>(_candidateAvatars), _mapAvatarsToData<Object>(_rejectedAvatars)),
    );
  }
}
