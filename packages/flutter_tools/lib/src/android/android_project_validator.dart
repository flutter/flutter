// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:xml/xml.dart';

import '../base/file_system.dart';
import '../project.dart';
import '../project_validator.dart';
import '../project_validator_result.dart';

/// A validator that checks the AndroidManifest.xml file for misplaced Flutter metadata keys.
class AndroidManifestProjectValidator extends ProjectValidator {
  const AndroidManifestProjectValidator();

  static const Set<String> _applicationKeys = <String>{
    'io.flutter.embedding.android.AOTSharedLibraryName',
    'io.flutter.embedding.engine.loader.FlutterLoader.aot-shared-library-name',
    'io.flutter.embedding.android.FlutterAssetsDir',
    'io.flutter.embedding.engine.loader.FlutterLoader.flutter-assets-dir',
    'io.flutter.embedding.android.OldGenHeapSize',
    'io.flutter.embedding.android.EnableImpeller',
    'io.flutter.embedding.android.ImpellerBackend',
    'io.flutter.embedding.android.EnableDartProfiling',
    'io.flutter.embedding.android.ProfileStartup',
    'io.flutter.embedding.android.TraceStartup',
    'io.flutter.embedding.android.MergedPlatformUIThread',
    'io.flutter.embedding.android.VmSnapshotData',
    'io.flutter.embedding.android.IsolateSnapshotData',
    'io.flutter.embedding.android.EnableHcpp',
    'io.flutter.embedding.android.EnableFlutterGPU',
    'io.flutter.embedding.android.ImpellerLazyShaderInitialization',
    'io.flutter.embedding.android.ImpellerAntialiasLines',
    'io.flutter.embedding.android.EnableOpenGLGPUTracing',
    'io.flutter.embedding.android.EnableVulkanGPUTracing',
    'io.flutter.embedding.android.SkiaDeterministicRendering',
    'io.flutter.embedding.android.EnableSoftwareRendering',
    'io.flutter.embedding.android.UseTestFonts',
    'io.flutter.embedding.android.VMServicePort',
    'io.flutter.embedding.android.EnableVulkanValidation',
    'io.flutter.embedding.android.TestFlag',
    'io.flutter.embedding.android.LeakVM',
    'io.flutter.embedding.android.StartPaused',
    'io.flutter.embedding.android.DisableServiceAuthCodes',
    'io.flutter.embedding.android.EndlessTraceBuffer',
    'io.flutter.embedding.android.TraceSkia',
    'io.flutter.embedding.android.TraceSkiaAllowList',
    'io.flutter.embedding.android.TraceSystrace',
    'io.flutter.embedding.android.TraceToFile',
    'io.flutter.embedding.android.ProfileMicrotasks',
    'io.flutter.embedding.android.DumpSkpOnShaderCompilation',
    'io.flutter.embedding.android.PurgePersistentCache',
    'io.flutter.embedding.android.VerboseLogging',
    'io.flutter.embedding.android.DartFlags',
    'io.flutter.embedding.android.DisableMergedPlatformUIThread',
    'io.flutter.network-policy',
    'io.flutter.automatically-register-plugins',
  };

  static const Set<String> _activityKeys = <String>{
    'io.flutter.Entrypoint',
    'io.flutter.EntrypointUri',
    'io.flutter.InitialRoute',
    'io.flutter.embedding.android.NormalTheme',
    'io.flutter.embedding.android.SplashScreenDrawable',
    'flutter_deeplinking_enabled',
  };

  @override
  Future<List<ProjectValidatorResult>> start(FlutterProject project) async {
    final results = <ProjectValidatorResult>[];
    final File manifestFile = project.android.appManifestFile;

    if (!manifestFile.existsSync()) {
      results.add(
        const ProjectValidatorResult(
          name: 'AndroidManifest.xml',
          value: 'Manifest file not found',
          status: StatusProjectValidator.warning,
        ),
      );
      return results;
    }

    XmlDocument document;
    try {
      document = XmlDocument.parse(await manifestFile.readAsString());
    } on XmlException catch (e) {
      results.add(
        ProjectValidatorResult(
          name: 'AndroidManifest.xml',
          value: 'Error parsing XML: $e',
          status: StatusProjectValidator.error,
        ),
      );
      return results;
    } on FileSystemException catch (e) {
      results.add(
        ProjectValidatorResult(
          name: 'AndroidManifest.xml',
          value: 'Error reading manifest: $e',
          status: StatusProjectValidator.error,
        ),
      );
      return results;
    }

    final Iterable<XmlElement> metaDataElements = document.findAllElements('meta-data');
    for (final metaData in metaDataElements) {
      final String? name = metaData.getAttribute(
        'name',
        namespace: 'http://schemas.android.com/apk/res/android',
      );
      if (name == null) {
        continue;
      }

      final XmlNode? parent = metaData.parent;
      if (parent is XmlElement) {
        final String parentName = parent.name.local;
        final bool isActivityParent = parentName == 'activity' || parentName == 'activity-alias';
        if (_activityKeys.contains(name) && !isActivityParent) {
          results.add(
            ProjectValidatorResult(
              name: name,
              value:
                  'Declared in <$parentName> but must be declared in <activity> or <activity-alias>',
              status: StatusProjectValidator.error,
            ),
          );
        } else if (_applicationKeys.contains(name) && parentName != 'application') {
          results.add(
            ProjectValidatorResult(
              name: name,
              value: 'Declared in <$parentName> but must be declared in <application>',
              status: StatusProjectValidator.error,
            ),
          );
        }
      }
    }

    if (results.isEmpty) {
      results.add(
        const ProjectValidatorResult(
          name: 'AndroidManifest.xml',
          value: 'No issues found',
          status: StatusProjectValidator.success,
        ),
      );
    }

    return results;
  }

  @override
  bool supportsProject(FlutterProject project) {
    return project.android.existsSync();
  }

  @override
  String get title => 'Android Manifest';
}
