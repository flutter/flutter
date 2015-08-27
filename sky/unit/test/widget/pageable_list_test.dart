import 'package:sky/widgets.dart';
import 'package:test/test.dart';
import 'package:quiver/testing/async.dart';

import 'widget_tester.dart';

void main() {
  test('Scrolling changes page', () {
    WidgetTester tester = new WidgetTester();

    List<int> pages = [0, 1, 2, 3, 4, 5];
    Size pageSize = new Size(200.0, 200.0);
    int currentPage;

    Widget buildPage(int page) {
      return new Container(
        key: new StringKey(page.toString()),
        width: pageSize.width,
        height: pageSize.height,
        child: new Text(page.toString())
      );
    }

    Widget builder() {
      return new Container(
        height: pageSize.height,
        child: new PageableList<int>(
          padding: new EdgeDims.symmetric(horizontal: 10.0),
          items: pages,
          itemBuilder: buildPage,
          scrollDirection: ScrollDirection.horizontal,
          itemExtent: pageSize.width,
          pageChanged: (int page) {
            currentPage = page;
          }
        )
      );
    }

    tester.pumpFrame(builder);
    // TODO(abarth): We shouldn't need to pump a second frame here.
    tester.pumpFrame(builder);

    expect(currentPage, isNull);
    new FakeAsync().run((async) {
      tester.scroll(tester.findText('1'), new Offset(300.0, 0.0));
      // One frame to start the animation, a second to complete it.
      tester.pumpFrame(builder);
      tester.pumpFrame(builder, 5000.0);
      async.elapse(new Duration(seconds: 5));
      expect(currentPage, equals(2));
    });
  });
}
