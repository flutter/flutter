import 'package:flutter_driver/flutter_driver.dart';

class StubFinder extends SerializableFinder {
  StubFinder(this.keyString);

  final String keyString;

  @override
  String get finderType => 'Stub';

  @override
  Map<String, String> serialize() {
    return super.serialize()..addAll({'keyString': keyString});
  }
}
