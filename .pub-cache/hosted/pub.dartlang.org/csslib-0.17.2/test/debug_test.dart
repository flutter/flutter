library debug;

import 'package:test/test.dart';
import 'testing.dart';

void main() {
  test('excercise debug', () {
    var style = parseCss(_input);

    var debugValue = style.toDebugString();
    expect(debugValue, isNotNull);

    var style2 = style.clone();

    expect(style2.toDebugString(), debugValue);
  });
}

const String _input = r'''
.foo {
background-color: #191919;
width: 10PX;
height: 22mM !important;
border-width: 20cm;
margin-width: 33%;
border-height: 30EM;
width: .6in;
length: 1.2in;
-web-stuff: -10Px;
}''';
