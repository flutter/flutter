part of widgets;

abstract class ButtonBase extends Component {

  bool _highlight = false;

  ButtonBase({ Object key }) : super(key: key);

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
