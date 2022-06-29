import 'dart:collection';

class Package {
  Package({
    required this.name,
    required this.version,
    required this.source,
    required this.dependencies,
  });
  final String name;
  final String version;
  final String source;
  final List<String> dependencies;

  static Package fromHashMap(dynamic packageInfo) {
    String name = '';
    String version = '';
    String source = '';
    List<dynamic> dependencies = <dynamic>[];
    
    if (packageInfo is LinkedHashMap) {
      LinkedHashMap<String, dynamic> info = packageInfo as LinkedHashMap<String, dynamic>;
      if (info.containsKey('name')) {
        name = info['name'] as String;
      }
      if (info.containsKey('version')) {
        version = info['version'] as String;
      }
      if (info.containsKey('source')) {
        source = info['source'] as String;
      }
      if (info.containsKey('dependencies')) {
        dependencies = info['dependencies'] as List<dynamic>;
      }
    }
    return Package(
      name: name,
      version: version,
      source: source,
      dependencies: dependencies.map((e) => e.toString()).toList(),
    );
  }

}
class DartPubJson {
  DartPubJson(this._json);
  final LinkedHashMap<String, dynamic> _json;
  final List<Package> _packages = <Package>[];

  List<Package> get packages {
    if (_packages.isNotEmpty) {
      return _packages;
    }
    if (_json.containsKey('packages')) {
      final List<dynamic> packagesInfo = _json['packages'] as List<dynamic>;
      for (final dynamic info in packagesInfo) {
        _packages.add(Package.fromHashMap(info));
      }
    }
    return _packages;
  }
}
