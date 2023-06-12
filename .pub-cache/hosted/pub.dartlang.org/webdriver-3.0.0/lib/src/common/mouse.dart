/// Common mouse button for webdriver.
///
/// Please refer to both json wire spec here:
/// https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#sessionsessionidclick
/// and w3c spec here: https://w3c.github.io/uievents/#dom-mouseevent-button
class MouseButton {
  /// The primary button is usually the left button or the only button on
  /// single-button devices, used to activate a user interface control or select
  /// text.
  static const MouseButton primary = MouseButton(0);

  /// The auxiliary button is usually the middle button, often combined with a
  /// mouse wheel.
  static const MouseButton auxiliary = MouseButton(1);

  /// The secondary button is usually the right button, often used to display a
  /// context menu.
  static const MouseButton secondary = MouseButton(2);

  /// Optional button to fire back action on a mouse. Defined in W3C.
  static const MouseButton x1 = MouseButton(3);

  /// Optional button to fire forward action on a mouse. Defined in W3C.
  static const MouseButton x2 = MouseButton(4);

  final int value;

  /// [value] for a mouse button is defined in
  /// https://w3c.github.io/uievents/#widl-MouseEvent-button
  const MouseButton(this.value);
}
