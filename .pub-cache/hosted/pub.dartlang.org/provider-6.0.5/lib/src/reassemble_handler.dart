import 'package:flutter/foundation.dart' show BindingBase;
import 'package:flutter/widgets.dart' show Element;

/// If you need your provider to be notified when 'Hot Reload' occurs,
/// use this class
///
/// ```dart
/// class MyChangeNotifier extends ChangeNotifier with ReassembleHandler {}
/// ```
// ignore: one_member_abstracts
abstract class ReassembleHandler {
  /// Called when 'Hot Reload' occurs
  ///
  /// See also:
  ///
  ///  * [Element.reassemble]
  ///  * [BindingBase.reassembleApplication]
  void reassemble();
}
