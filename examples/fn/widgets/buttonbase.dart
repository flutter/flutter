part of widgets;

abstract class ButtonBase extends MaterialComponent {

  bool _highlight = false;

  ButtonBase({ Object key }) : super(key: key) {
    events.listen('pointerdown', _handlePointerDown);
    events.listen('pointerup', _handlePointerUp);
    events.listen('pointercancel', _handlePointerCancel);
  }

  void _handlePointerDown(_) {
    setState(() {
      _highlight = true;
    });
  }
  void _handlePointerUp(_) {
    setState(() {
      _highlight = false;
    });
  }
  void _handlePointerCancel(_) {
    setState(() {
      _highlight = false;
    });
  }
}
