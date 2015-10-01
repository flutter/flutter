import 'package:sky/widgets.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

class Item {
  GlobalKey key1 = new GlobalKey();
  GlobalKey key2 = new GlobalKey();
  String toString() => "Item($key1, $key2)";
}
List<Item> items = [new Item(), new Item()];

class StatefulLeaf extends StatefulComponent {
  StatefulLeaf({ GlobalKey key }) : super(key: key);
  StatefulLeafState createState() => new StatefulLeafState();
}

class StatefulLeafState extends State<StatefulLeaf> {
  void test() { setState(() { }); }
  Widget build(BuildContext context) => new Text('leaf');
}

class KeyedWrapper extends StatelessComponent {
  KeyedWrapper(this.key1, this.key2);
  Key key1, key2;
  Widget build(BuildContext context) {
    return new Container(
      key: key1,
      child: new StatefulLeaf(
        key: key2
      )
    );
  }
}

Widget builder() {
  return new Column([
    new KeyedWrapper(items[1].key1, items[1].key2),
    new KeyedWrapper(items[0].key1, items[0].key2)
  ]);
}

void main() {
  test('duplicate key smoke test', () {
    WidgetTester tester = new WidgetTester();
    tester.pumpFrame(builder());
    StatefulLeafState leaf = tester.findStateOfType(StatefulLeafState);
    leaf.test();
    tester.pumpFrameWithoutChange();
    Item lastItem = items[1];
    items.remove(lastItem);
    items.insert(0, lastItem);
    tester.pumpFrame(builder()); // this marks the app dirty and rebuilds it
  });
}
