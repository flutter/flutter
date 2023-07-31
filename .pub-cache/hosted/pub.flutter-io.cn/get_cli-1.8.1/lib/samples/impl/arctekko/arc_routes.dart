import '../../interface/sample_interface.dart';

class ArcRouteSample extends Sample {
  String initial;
  ArcRouteSample(this.initial,
      {String path = 'lib/infrastructure/navigation/routes.dart'})
      : super(path);
  @override
  String get content => '''
class Routes {
  static Future<String> get initialRoute async {
    // TODO: implement method
    return $initial;
  }
}
''';
}
