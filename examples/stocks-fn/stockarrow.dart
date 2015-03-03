part of stocksapp;

class StockArrow extends Component {

  double percentChange;

  static Style _style = new Style('''
    width: 40px;
    height: 40px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 40px;
    margin-right: 16px;
    border: 1px solid transparent;'''
  );

  static Style _upStyle = new Style('''
    width: 0;
    height: 0;
    border-left: 9px solid transparent;
    border-right: 9px solid transparent;
    margin-bottom: 3px;
    border-bottom: 9px solid white;'''
  );

  static Style _downStyle = new Style('''
    width: 0;
    height: 0;
    border-left: 9px solid transparent;
    border-right: 9px solid transparent;
    margin-top: 3px;
    border-top: 9px solid white'''
  );

  StockArrow({ Object key, this.percentChange }) : super(key: key);

  final List<String> _kRedColors = [
    '#E57373',
    '#EF5350',
    '#F44336',
    '#E53935',
    '#D32F2F',
    '#C62828',
    '#B71C1C',
  ];

  final List<String> _kGreenColors = [
    '#81C784',
    '#66BB6A',
    '#4CAF50',
    '#43A047',
    '#388E3C',
    '#2E7D32',
    '#1B5E20',
  ];

  int _colorIndexForPercentChange(double percentChange) {
    // Currently the max is 10%.
    double maxPercent = 10.0;
    return max(0, ((percentChange.abs() / maxPercent) * _kGreenColors.length).floor());
  }

  String _colorForPercentChange(double percentChange) {
    if (percentChange > 0)
      return _kGreenColors[_colorIndexForPercentChange(percentChange)];
    return _kRedColors[_colorIndexForPercentChange(percentChange)];
  }

  Node render() {
    String border = _colorForPercentChange(percentChange).toString();
    bool up = percentChange > 0;
    String type = up ? 'bottom' : 'top';

    return new Container(
      inlineStyle: 'border-color: $border',
      style: _style,
      children: [
        new Container(
          inlineStyle: 'border-$type-color: $border',
          style: up ? _upStyle : _downStyle
        )
      ]
    );
  }
}
