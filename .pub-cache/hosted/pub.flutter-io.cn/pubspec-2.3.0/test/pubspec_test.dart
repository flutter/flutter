@Skip('not a real test')
import 'dart:io';

import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec/pubspec.dart';

import 'package:test/test.dart';

main() async {
  final PubSpec pubSpec = PubSpec(name: 'fred', dependencies: {
    'foo': PathReference('../foo'),
    'fred': HostedReference(VersionRange(min: Version(1, 2, 3)))
  });

  await pubSpec.save(await Directory.systemTemp.createTemp('delme'));
}
