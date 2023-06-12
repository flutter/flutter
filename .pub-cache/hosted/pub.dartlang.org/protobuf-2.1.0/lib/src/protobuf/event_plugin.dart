part of protobuf;

/// An EventPlugin receives callbacks when the fields of a GeneratedMessage
/// change.
///
/// A GeneratedMessage mixin can install a plugin by overriding the eventPlugin
/// property. The intent is provide mechanism, not policy; each mixin defines
/// its own public API, perhaps using streams.
///
/// This is a low-level, synchronous API. Event handlers are called in the
/// middle of protobuf changes. To avoid exposing half-finished changes
/// to user code, plugins should buffer events and send them asynchronously.
/// (See event_mixin.dart for an example.)
abstract class EventPlugin {
  /// Initializes the plugin.
  ///
  /// GeneratedMessage calls this once in its constructors.
  void attach(GeneratedMessage parent);

  /// If false, GeneratedMessage will skip calls to event handlers.
  bool get hasObservers;

  /// Called before setting a field.
  ///
  /// For repeated fields, this will be called when the list is created.
  /// (For example in getField and merge methods.)
  void beforeSetField(FieldInfo fi, newValue);

  /// Called before clearing a field.
  void beforeClearField(FieldInfo fi);
}
