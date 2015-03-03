part of widgets;

const String kAssetBase = '/sky/assets/material-design-icons';

class Icon extends Component {

  Style style;
  int size;
  String type;
  sky.EventListener onClick;

  Icon({
    String key,
    this.style,
    this.size,
    this.type: '',
    this.onClick
  }) : super(key: key);

  Node render() {
    String category = '';
    String subtype = '';
    List<String> parts = type.split('/');
    if (parts.length == 2) {
      category = parts[0];
      subtype = parts[1];
    }

    return new Image(
      style: style,
      onClick: onClick,
      width: size,
      height: size,
      src: '${kAssetBase}/${category}/2x_web/ic_${subtype}_${size}dp.png'
    );
  }
}
