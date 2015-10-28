import 'dart:async';
import 'dart:io';

import 'package:den_api/den_api.dart';
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';

// set this to true when we decide to ship 0.1.0
const bool haveWeEverReleasedAPointRelease = false;

class FlutterPubspec {
  static Future<FlutterPubspec> load(String path) async {
    return new FlutterPubspec.fromPubspec(await Pubspec.load(path));
  }

  FlutterPubspec.fromPubspec(this._data) {
    _openPubspecs.add(this);
  }

  final Pubspec _data;

  String get name => _data.name;
  Version get version => _data.version;

  PackageDep get asDependency {
    return new PackageDep(name, 'hosted', version, '');
  }

  void bumpVersion({ bool breakingChange }) {
    _data.bump(haveWeEverReleasedAPointRelease && breakingChange ? ReleaseType.minor : ReleaseType.patch);
    print('$name is now at $version');
  }

  void setDependency(FlutterPubspec dependency) {
    _data.addDependency(dependency.asDependency);
  }

  void setDependencyIfNecessary(FlutterPubspec dependency) {
    if (_data.dependencies.containsKey(dependency.name))
      _data.addDependency(dependency.asDependency);
  }

  void _save() {
    _data.save();
  }

  static List<FlutterPubspec> _openPubspecs = <FlutterPubspec>[];
  static void saveAll() {
    for (FlutterPubspec file in _openPubspecs)
      file._save();
  }
}

main() async {
  bool breakingChange = true;


  // The published packages

  FlutterPubspec flutterEngine = await FlutterPubspec.load('sky/packages/sky_engine')
  ..bumpVersion(breakingChange: breakingChange);

  FlutterPubspec flutterServices = await FlutterPubspec.load('sky/packages/sky_services')
  ..bumpVersion(breakingChange: breakingChange);

  FlutterPubspec flutterFlx = await FlutterPubspec.load('sky/packages/flx')
  ..bumpVersion(breakingChange: breakingChange)
  ..setDependency(flutterServices);

  FlutterPubspec flutter = await FlutterPubspec.load('sky/packages/sky')
  ..bumpVersion(breakingChange: breakingChange)
  ..setDependency(flutterEngine)
  ..setDependency(flutterServices);

  FlutterPubspec flutterSprites = await FlutterPubspec.load('skysprites')
  ..bumpVersion(breakingChange: breakingChange)
  ..setDependency(flutter);


  // The internal packages

  await FlutterPubspec.load('sky/packages/updater')
  ..setDependency(flutter)
  ..setDependency(flutterSprites);

  await FlutterPubspec.load('sky/unit')
  ..setDependency(flutter);

  await FlutterPubspec.load('sky/packages/workbench')
  ..setDependency(flutterServices)
  ..setDependency(flutterFlx)
  ..setDependency(flutter)
  ..setDependency(flutterSprites);

  Directory examples = new Directory('examples');
  await for (FileSystemEntity entity in examples.list(recursive: true, followLinks: false)) {
    if (entity is File && path.basename(entity.path) == Pubspec.basename) {
      await FlutterPubspec.load(entity.path)
      ..setDependency(flutter)
      ..setDependencyIfNecessary(flutterSprites);
    }
  }

  // we don't update these, since they're their own things and don't depend on
  // the above packages:
  //   sky/tools/pubspec_maintenance/pubspec.yaml
  //   sky/packages/material_design_icons/pubspec.yaml

  FlutterPubspec.saveAll();
}
