
// We ignore this warning because mouse cursor has a lot of enum-like constants,
// which is clearer when grouped in a class.
// ignore: avoid_classes_with_only_static_members
/// Integer constants which represent system mouse cursors from various
/// platforms.
///
/// This is a collection of all system mouse cursors supported by all platforms
/// that Flutter is interested in. The implementation to these cursors are left
/// to platforms, which means multiple constants might result in the same cursor,
/// and the same constant might look different across platforms.
///
/// The integer values of the constants are intentionally randomized (results
/// of hashing). When defining custom cursors, you are free to choose how
/// to pick values, as long as the result does not collide with existing
/// values and is consistent between platforms and the framework.
class MouseCursors {
  // Constants here must be kept in sync with the following files:
  //
  // * MouseCursorController.java

  /// A special value that tells Flutter to release the control of cursors.
  ///
  /// A layer with this value will absorb the search for mouse cursor
  /// configuration, but the pointer's cursor will not be changed when it enters
  /// or is hovering this layer. This value is typically used on a platform view
  /// or other layers that manages the cursor by itself.
  ///
  /// This constant is parsed by [MouseCursorManger] and should not be sent
  /// to the platforms over the channel.
  static const int releaseControl = 0xc3c7870d;

  /// Displays no cursor at the pointer.
  static const int none = 0x334c4a4c;

  /// The platform-dependent basic cursor. Typically the shape of an arrow.
  static const int basic = 0xf17aaabc;

  /// A cursor that indicates links or something that needs to be emphasized
  /// to be clickable. Typically the shape of a pointing hand.
  static const int click = 0xa8affc08;

  /// A cursor that indicates a selectable text. Typically the shape of an
  /// I-beam.
  static const int text = 0x1cb251ec;

  /// A cursor that indicates an unpermitted action. Typically the shape of a
  /// circle with a diagnal line.
  static const int no = 0x7fa3b767;

  /// A cursor that indicates something that can be dragged. Typically the shape
  /// of an open hand.
  static const int grab = 0x28b91f80;

  /// A cursor that indicates something that is being dragged. Typically the
  /// shape of a closed hand.
  static const int grabbing = 0x6631ce3e;
}
