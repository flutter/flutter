import 'package:recase/recase.dart';

import '../../common/utils/pubspec/pubspec_utils.dart';
import '../interface/sample_interface.dart';

/// [Sample] file from Provider file creation.
class ProviderSample extends Sample {
  final String _fileName;
  final bool isServer;
  final bool createEndpoints;
  final String modelPath;
  String? _namePascal;
  String? _nameLower;
  ProviderSample(this._fileName,
      {bool overwrite = false,
      this.createEndpoints = false,
      this.modelPath = '',
      this.isServer = false,
      String path = ''})
      : super(path, overwrite: overwrite) {
    _namePascal = _fileName.pascalCase;
    _nameLower = _fileName.toLowerCase();
  }

  String get _import => isServer
      ? "import 'package:get_server/get_server.dart';"
      : "import 'package:get/get.dart';";
  String get _importModelPath => createEndpoints
      ? "import 'package:${PubspecUtils.projectName}/$modelPath';\n"
      : '\n';

  @override
  String get content => '''$_import
$_importModelPath
class ${_fileName.pascalCase}Provider extends GetConnect {
@override
void onInit() {
$_defaultEncoder httpClient.baseUrl = 'YOUR-API-URL';
}
$_defaultEndpoint}
''';

  String get _defaultEndpoint => createEndpoints
      ? ''' 
\tFuture<$_namePascal?> get$_namePascal(int id) async {
\t\tfinal response = await get('$_nameLower/\$id');
\t\treturn response.body;
}


\tFuture<Response<$_namePascal>> post$_namePascal($_namePascal $_nameLower) async => 
\t\tawait post('$_nameLower', $_nameLower);
\tFuture<Response> delete$_namePascal(int id) async => 
\t\tawait delete('$_nameLower/\$id');
'''
      : '\n';
  String get _defaultEncoder => createEndpoints
      ? '''\t\thttpClient.defaultDecoder = (map){
if(map is Map<String, dynamic>) return $_namePascal.fromJson(map); 
if(map is List) return map.map((item)=> $_namePascal.fromJson(item)).toList();
};\n'''
      : '\n';
}
