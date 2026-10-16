// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/experimental/extension_artifact_manager.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart' hide HostPlatform;
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:flutter_tools_extension_linux_prototype/flutter_tools_extension_linux_prototype.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';

import '../../src/fakes.dart';

final class _FakeArtifactService extends ArtifactService {
  _FakeArtifactService(this.artifacts);

  final List<ArtifactDependency> artifacts;

  @override
  Future<List<ArtifactDependency>> downloadArtifacts({
    required HostPlatform hostPlatform,
    String? targetPlatform,
  }) async {
    return artifacts;
  }
}

void main() {
  group('ExtensionArtifactManager', () {
    late MemoryFileSystem fs;
    late BufferLogger logger;
    late FakeOperatingSystemUtils osUtils;

    setUp(() {
      fs = MemoryFileSystem.test();
      logger = BufferLogger.test();
      osUtils = FakeOperatingSystemUtils();
    });

    test('resolves shared cache directory from cacheDir override, DART_DATA_HOME, HOME, and LOCALAPPDATA', () {
      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(),
      );

      final Directory explicitDir = fs.directory('/explicit/cache');
      final withOverride = ExtensionArtifactManager(
        cacheDir: explicitDir,
        extensionManager: manager,
        featureFlags: TestFeatureFlags(),
        fileSystem: fs,
        logger: logger,
        osUtils: osUtils,
        platform: FakePlatform(environment: const <String, String>{'DART_DATA_HOME': '/dart_data'}),
      );
      expect(withOverride.artifactsCacheDirectory.path, '/explicit/cache');

      final withDartDataHome = ExtensionArtifactManager(
        extensionManager: manager,
        featureFlags: TestFeatureFlags(),
        fileSystem: fs,
        logger: logger,
        osUtils: osUtils,
        platform: FakePlatform(
          environment: const <String, String>{'DART_DATA_HOME': '/dart_data', 'HOME': '/home/user'},
        ),
      );
      expect(
        withDartDataHome.artifactsCacheDirectory.path,
        '/dart_data/flutter_tool_extensions/artifacts',
      );

      final withHomeFallback = ExtensionArtifactManager(
        extensionManager: manager,
        featureFlags: TestFeatureFlags(),
        fileSystem: fs,
        logger: logger,
        osUtils: osUtils,
        platform: FakePlatform(environment: const <String, String>{'HOME': '/home/user'}),
      );
      expect(
        withHomeFallback.artifactsCacheDirectory.path,
        '/home/user/.flutter_tool_extensions/artifacts',
      );

      final windowsFs = MemoryFileSystem.test(style: FileSystemStyle.windows);
      final withWindowsLocalAppData = ExtensionArtifactManager(
        extensionManager: manager,
        featureFlags: TestFeatureFlags(),
        fileSystem: windowsFs,
        logger: logger,
        osUtils: osUtils,
        platform: FakePlatform(
          operatingSystem: 'windows',
          environment: const <String, String>{'LOCALAPPDATA': r'C:\Users\user\AppData\Local'},
        ),
      );
      expect(
        withWindowsLocalAppData.artifactsCacheDirectory.path,
        r'C:\Users\user\AppData\Local\flutter_tool_extensions\artifacts',
      );

      final withWindowsUserProfile = ExtensionArtifactManager(
        extensionManager: manager,
        featureFlags: TestFeatureFlags(),
        fileSystem: windowsFs,
        logger: logger,
        osUtils: osUtils,
        platform: FakePlatform(
          operatingSystem: 'windows',
          environment: const <String, String>{'USERPROFILE': r'C:\Users\user'},
        ),
      );
      expect(
        withWindowsUserProfile.artifactsCacheDirectory.path,
        r'C:\Users\user\.flutter_tool_extensions\artifacts',
      );
    });

    test('does nothing when tool extensions feature flag is disabled', () async {
      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(),
      );
      final artifactManager = ExtensionArtifactManager(
        extensionManager: manager,
        featureFlags: TestFeatureFlags(),
        fileSystem: fs,
        logger: logger,
        osUtils: osUtils,
        platform: FakePlatform(environment: const <String, String>{'DART_DATA_HOME': '/dart_data'}),
      );

      await artifactManager.ensureArtifactsDownloaded();
      expect(fs.directory('/dart_data').existsSync(), isFalse);
      expect(fs.currentDirectory.childDirectory('.dart_tool').existsSync(), isFalse);
      await manager.dispose();
    });

    test('downloads and verifies artifact by SHA-256 into content-addressed cache and skips on cache hit', () async {
      final List<int> content = utf8.encode('custom binary payload');
      final contentSha256 = sha256.convert(content).toString();

      void entryPoint(SendPort sendPort) {
        ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[
            _FakeArtifactService(<ArtifactDependency>[
              ArtifactDependency(
                name: 'my_custom_bin',
                sha256: contentSha256,
                url: Uri.parse('https://example.com/my_custom_bin'),
                hostPlatform: HostPlatform.linux_x64,
                targetPlatform: 'linux-x64',
              ),
            ]),
          ],
          extensionName: 'custom_ext',
          supportedPlatforms: const <String>{'linux'},
        );
      }

      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        entryPoints: <ExtensionEntryPoint>[entryPoint],
      );

      var downloadCount = 0;
      final httpClient = _FakeHttpClient((Uri url) {
        downloadCount++;
        return _FakeHttpClientResponse(HttpStatus.ok, content);
      });

      final artifactManager = ExtensionArtifactManager(
        extensionManager: manager,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        fileSystem: fs,
        httpClient: httpClient,
        logger: logger,
        osUtils: osUtils,
        platform: FakePlatform(environment: const <String, String>{'DART_DATA_HOME': '/dart_data'}),
      );

      await artifactManager.ensureArtifactsDownloaded(targetPlatforms: const <String>{'linux-x64'});

      expect(downloadCount, 1);
      final File artifactFile = fs.file(
        '/dart_data/flutter_tool_extensions/artifacts/custom_ext/$contentSha256/my_custom_bin',
      );
      expect(artifactFile.existsSync(), isTrue);
      expect(artifactFile.readAsBytesSync(), equals(content));
      expect(fs.currentDirectory.childDirectory('.dart_tool').existsSync(), isFalse);

      // Second call should verify SHA-256 and skip downloading.
      await artifactManager.ensureArtifactsDownloaded(targetPlatforms: const <String>{'linux-x64'});
      expect(downloadCount, 1);

      // Corrupt the cached file; next call should detect SHA-256 mismatch and re-download.
      artifactFile.writeAsStringSync('corrupted bytes');
      await artifactManager.ensureArtifactsDownloaded(targetPlatforms: const <String>{'linux-x64'});
      expect(downloadCount, 2);
      expect(artifactFile.readAsBytesSync(), equals(content));

      await manager.dispose();
    });

    test('unzips .zip artifacts into content-addressed directory and writes stamp file', () async {
      final List<int> zipContent = utf8.encode('fake zip archive bytes');
      final zipSha256 = sha256.convert(zipContent).toString();

      void entryPoint(SendPort sendPort) {
        ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[
            _FakeArtifactService(<ArtifactDependency>[
              ArtifactDependency(
                name: 'engine_bundle',
                sha256: zipSha256,
                url: Uri.parse('https://example.com/engine_bundle.zip'),
                hostPlatform: HostPlatform.linux_x64,
                targetPlatform: 'custom-embedder-arm64',
              ),
            ]),
          ],
          extensionName: 'embedder_ext',
          supportedPlatforms: const <String>{'linux'},
        );
      }

      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        entryPoints: <ExtensionEntryPoint>[entryPoint],
      );

      var downloadCount = 0;
      final httpClient = _FakeHttpClient((Uri url) {
        downloadCount++;
        return _FakeHttpClientResponse(HttpStatus.ok, zipContent);
      });
      final unzipOsUtils = _UnzipTrackingOsUtils();

      final Directory customCacheDir = fs.directory('/custom/cache');
      final artifactManager = ExtensionArtifactManager(
        cacheDir: customCacheDir,
        extensionManager: manager,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        fileSystem: fs,
        httpClient: httpClient,
        logger: logger,
        osUtils: unzipOsUtils,
        platform: FakePlatform(),
      );

      await artifactManager.ensureArtifactsDownloaded(
        targetPlatforms: const <String>{'custom-embedder-arm64'},
      );

      expect(downloadCount, 1);
      expect(unzipOsUtils.unzipCount, 1);
      final Directory extractedDir = customCacheDir
          .childDirectory('embedder_ext')
          .childDirectory(zipSha256)
          .childDirectory('engine_bundle');
      expect(extractedDir.existsSync(), isTrue);
      expect(extractedDir.childFile('extracted.txt').existsSync(), isTrue);

      // Subsequent call hits verified stamp and does not re-download.
      await artifactManager.ensureArtifactsDownloaded(
        targetPlatforms: const <String>{'custom-embedder-arm64'},
      );
      expect(downloadCount, 1);
      expect(unzipOsUtils.unzipCount, 1);

      await manager.dispose();
    });

    test(
      'concurrent ensureArtifactsDownloaded calls for same artifact are safe and deduplicated',
      () async {
        final List<int> content = utf8.encode('concurrent payload');
        final contentSha256 = sha256.convert(content).toString();

        void entryPoint(SendPort sendPort) {
          ToolExtensionEntryPoint.run(
            sendPort,
            <ToolExtensionService>[
              _FakeArtifactService(<ArtifactDependency>[
                ArtifactDependency(
                  name: 'concurrent_bin',
                  sha256: contentSha256,
                  url: Uri.parse('https://example.com/concurrent_bin'),
                  hostPlatform: HostPlatform.linux_x64,
                ),
              ]),
            ],
            extensionName: 'concurrent_ext',
            supportedPlatforms: const <String>{'linux'},
          );
        }

        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
          entryPoints: <ExtensionEntryPoint>[entryPoint],
        );

        var downloadCount = 0;
        final httpClient = _FakeHttpClient((Uri url) {
          downloadCount++;
          return _FakeHttpClientResponse(HttpStatus.ok, content);
        });

        final Directory cacheDir = fs.directory('/concurrent_cache');
        final artifactManager = ExtensionArtifactManager(
          cacheDir: cacheDir,
          extensionManager: manager,
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
          fileSystem: fs,
          httpClient: httpClient,
          logger: logger,
          osUtils: osUtils,
          platform: FakePlatform(),
        );

        await Future.wait(<Future<void>>[
          artifactManager.ensureArtifactsDownloaded(),
          artifactManager.ensureArtifactsDownloaded(),
          artifactManager.ensureArtifactsDownloaded(),
        ]);

        expect(downloadCount, 1);
        final File cachedFile = cacheDir
            .childDirectory('concurrent_ext')
            .childDirectory(contentSha256)
            .childFile('concurrent_bin');
        expect(cachedFile.existsSync(), isTrue);
        expect(cachedFile.readAsBytesSync(), equals(content));

        await manager.dispose();
      },
    );

    test('throws ToolExit when SHA-256 checksum mismatches', () async {
      final List<int> content = utf8.encode('corrupted payload');

      void entryPoint(SendPort sendPort) {
        ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[
            _FakeArtifactService(<ArtifactDependency>[
              ArtifactDependency(
                name: 'bad_bin',
                sha256: '0000000000000000000000000000000000000000000000000000000000000000',
                url: Uri.parse('https://example.com/bad_bin'),
                hostPlatform: HostPlatform.linux_x64,
              ),
            ]),
          ],
          extensionName: 'bad_ext',
          supportedPlatforms: const <String>{'linux'},
        );
      }

      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        entryPoints: <ExtensionEntryPoint>[entryPoint],
      );

      final httpClient = _FakeHttpClient(
        (Uri url) => _FakeHttpClientResponse(HttpStatus.ok, content),
      );

      final artifactManager = ExtensionArtifactManager(
        cacheDir: fs.directory('/bad_cache'),
        extensionManager: manager,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        fileSystem: fs,
        httpClient: httpClient,
        logger: logger,
        osUtils: osUtils,
        platform: FakePlatform(),
      );

      await expectLater(
        artifactManager.ensureArtifactsDownloaded(),
        throwsA(
          isA<ToolExit>().having(
            (ToolExit e) => e.message,
            'message',
            contains('SHA-256 checksum mismatch for artifact "bad_bin"'),
          ),
        ),
      );

      await manager.dispose();
    });

    test('works with LinuxArtifactService prototype extension', () async {
      const content = <int>[]; // Empty bytes match e3b0c44298fc...
      const expectedSha = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
      );

      final Directory cacheDir = fs.directory('/shared_cache');
      final Directory shaDir = cacheDir
          .childDirectory('flutter_tools_extension_linux_prototype')
          .childDirectory(expectedSha);
      shaDir.childFile('linux-x64-custom-artifact')
        ..createSync(recursive: true)
        ..writeAsBytesSync(content);

      var downloadTriggered = false;
      final httpClient = _FakeHttpClient((Uri url) {
        downloadTriggered = true;
        return _FakeHttpClientResponse(HttpStatus.ok, content);
      });

      final artifactManager = ExtensionArtifactManager(
        cacheDir: cacheDir,
        extensionManager: manager,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        fileSystem: fs,
        httpClient: httpClient,
        logger: logger,
        osUtils: osUtils,
        platform: FakePlatform(),
      );

      await artifactManager.ensureArtifactsDownloaded(targetPlatforms: const <String>{'linux'});
      expect(downloadTriggered, isFalse);

      await manager.dispose();
    });
  });
}

class _UnzipTrackingOsUtils extends FakeOperatingSystemUtils {
  int unzipCount = 0;

  @override
  void unzip(File file, Directory targetDirectory) {
    unzipCount++;
    targetDirectory.childFile('extracted.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync('extracted');
  }
}

class _FakeHttpClient extends Fake implements HttpClient {
  _FakeHttpClient(this._handler);

  final _FakeHttpClientResponse Function(Uri url) _handler;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest(url, _handler);
}

class _FakeHttpClientRequest extends Fake implements HttpClientRequest {
  _FakeHttpClientRequest(this._url, this._handler);

  final Uri _url;
  final _FakeHttpClientResponse Function(Uri url) _handler;

  @override
  Future<HttpClientResponse> close() async => _handler(_url);
}

class _FakeHttpClientResponse extends Stream<List<int>> with Fake implements HttpClientResponse {
  _FakeHttpClientResponse(this.statusCode, this._bytes);

  @override
  final int statusCode;

  final List<int> _bytes;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable(<List<int>>[_bytes])
        .listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}
