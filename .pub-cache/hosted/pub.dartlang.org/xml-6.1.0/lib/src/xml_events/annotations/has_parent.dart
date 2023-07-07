import 'package:meta/meta.dart';

import '../events/start_element.dart';

/// Mixin with information about the parent event.
mixin XmlHasParent {
  /// Hold a lazy reference to the parent event.
  XmlStartElementEvent? _parent;

  /// Return the parent event of type [XmlStartElementEvent], or `null`.
  XmlStartElementEvent? get parent => _parent;

  /// Return the parent event of type [XmlStartElementEvent], or `null`.
  @Deprecated('Use XmlEvent.parent instead.')
  XmlStartElementEvent? get parentEvent => _parent;

  /// Internal helper to attach the parent to the event, do not call directly.
  @internal
  void attachParent(XmlStartElementEvent? parent) {
    assert(_parent == null, 'Parent is already initialized.');
    _parent = parent;
  }
}
