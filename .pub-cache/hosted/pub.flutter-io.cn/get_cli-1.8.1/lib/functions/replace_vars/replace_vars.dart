import 'package:recase/recase.dart';

import '../../common/utils/pubspec/pubspec_utils.dart';

String replaceVars(String content, String name) {
  return content
      .replaceAll('@view', '${name.pascalCase}View')
      .replaceAll('@screen', '${name.pascalCase}Screen')
      .replaceAll('@controller', '${name.pascalCase}Controller')
      .replaceAll('@binding', '${name.pascalCase}Binding')
      .replaceAll('@import', PubspecUtils.getPackageImport)
      .replaceAll('@package', PubspecUtils.projectName!);
}
