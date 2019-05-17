import 'package:flutter/widgets.dart';

// @immutable
// /// TODO
// class ContextMenuDetails {
//   /// TODO
//   ContextMenuDetails({
//     @required this.isOpen,
//     this.globalLocation,
//     this.context,
//     this.value,
//   }) : assert(isOpen != null),
//        assert(!isOpen || value == null),
//        assert(isOpen == (globalLocation != null)),
//        assert(isOpen == (context != null));

//   /// TODO
//   final bool isOpen;

//   /// TODO
//   final Offset globalLocation;

//   /// TODO
//   final BuildContext context;

//   /// TODO
//   final dynamic value;
// }

typedef ContextMenuChangedCallback = void Function(bool isOpen, [dynamic value]);

@immutable
/// TODO
class ContextMenuActionDetails {
}

typedef ContextMenuAction = Future<void> Function(ContextMenuActionDetails details);
