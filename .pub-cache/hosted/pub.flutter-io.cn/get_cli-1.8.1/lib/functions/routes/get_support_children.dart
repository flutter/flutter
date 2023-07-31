import 'package:version/version.dart';

import '../../common/utils/pubspec/pubspec_utils.dart';
import '../find_file/find_file_by_name.dart';

/// Checks whether the installed version of get supports child routes
bool get supportChildrenRoutes {
  if (PubspecUtils.isServerProject) {
    return false;
  }
  var supportChildren = Version.parse('3.21.0').compareTo(
          PubspecUtils.getPackageVersion('get') ?? Version.parse('3.21.0')) <=
      0;
  if (supportChildren) {
    var routesFile = findFileByName('app_routes.dart');
    if (routesFile.path.isNotEmpty) {
      supportChildren =
          routesFile.readAsLinesSync().contains('abstract class _Paths {') ||
              routesFile.readAsLinesSync().contains('abstract class _Paths {}');
    } else {
      supportChildren = false;
    }
  }
  return supportChildren;
}
