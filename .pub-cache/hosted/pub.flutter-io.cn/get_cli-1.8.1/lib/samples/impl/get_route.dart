import '../interface/sample_interface.dart';

/// [Sample] file from [app_routes] file creation.
class RouteSample extends Sample {
  RouteSample({String path = 'lib/app/routes/app_routes.dart'}) : super(path);
  @override
  String get content => '''part of 'app_pages.dart';
// DO NOT EDIT. This is code generated via package:get_cli/get_cli.dart

abstract class Routes{
  Routes._();

}

abstract class _Paths {
  
  _Paths._();

}

''';
}
