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
import 'package:flutter_tools_extension_linux_prototype/src/artifact.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';

import '../../src/fakes.dart';

final class _FakeArtifactService extends ArtifactService {
  _FakeArtifactService(this.artifacts, {this.targetPlatformsObserver});

  final List<ArtifactDependency> artifacts;
  final SendPort? targetPlatformsObserver;

  @override
  Future<List<ArtifactDependency>> listRequiredArtifacts({
    required String engineVersion,
    required HostPlatform hostPlatform,
    Set<String>? targetPlatforms,
  }) async {
    targetPlatformsObserver?.send(targetPlatforms?.toList());
    return <ArtifactDependency>[
      for (final ArtifactDependency artifact in artifacts)
        if (artifact.matchesPlatforms(
          currentHostPlatform: hostPlatform,
          targetPlatforms: targetPlatforms,
        ))
          artifact,
    ];
  }
}

ExtensionEntryPoint _createMultiTargetEntryPoint({
  required List<ArtifactDependency> artifacts,
  required SendPort targetPlatformsObserver,
}) {
  return (SendPort sendPort) {
    ToolExtensionEntryPoint.run(
      sendPort,
      <ToolExtensionService>[
        _FakeArtifactService(artifacts, targetPlatformsObserver: targetPlatformsObserver),
      ],
      extensionName: 'multi_ext',
      supportedPlatforms: const <String>{'linux'},
    );
  };
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

    test('resolves shared cache directory from cacheDir override, DART_DATA_HOME, HOME, and LOCALAPPDATA, and throws ToolExit when unset', () {
      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(),
      );
      expect(manager.hostPlatformName, 'linux');

      final customHostManager = ExtensionManager(
        hostPlatform: HostPlatform('freebsd', .x64),
        logger: logger,
        featureFlags: TestFeatureFlags(),
      );
      expect(customHostManager.hostPlatformName, 'freebsd');

      final Directory explicitDir = fs.directory('/explicit/cache');
      final withOverride = ExtensionArtifactManager(
        cacheDir: explicitDir,
        extensionManager: manager,
        featureFlags: TestFeatureFlags(),
        toolContext: FakeToolContext(
          fs: fs,
          logger: logger,
          os: osUtils,
          platform: FakePlatform(
            environment: const <String, String>{'DART_DATA_HOME': '/dart_data'},
          ),
        ),
      );
      expect(withOverride.artifactsCacheDirectory.path, '/explicit/cache');

      final withDartDataHome = ExtensionArtifactManager(
        extensionManager: manager,
        featureFlags: TestFeatureFlags(),
        toolContext: FakeToolContext(
          fs: fs,
          logger: logger,
          os: osUtils,
          platform: FakePlatform(
            environment: const <String, String>{
              'DART_DATA_HOME': '/dart_data',
              'HOME': '/home/user',
            },
          ),
        ),
      );
      expect(
        withDartDataHome.artifactsCacheDirectory.path,
        '/dart_data/flutter_tool_extensions/artifacts',
      );

      final withHomeFallback = ExtensionArtifactManager(
        extensionManager: manager,
        featureFlags: TestFeatureFlags(),
        toolContext: FakeToolContext(
          fs: fs,
          logger: logger,
          os: osUtils,
          platform: FakePlatform(environment: const <String, String>{'HOME': '/home/user'}),
        ),
      );
      expect(
        withHomeFallback.artifactsCacheDirectory.path,
        '/home/user/.flutter_tool_extensions/artifacts',
      );

      final windowsFs = MemoryFileSystem.test(style: FileSystemStyle.windows);
      final withWindowsLocalAppData = ExtensionArtifactManager(
        extensionManager: manager,
        featureFlags: TestFeatureFlags(),
        toolContext: FakeToolContext(
          fs: windowsFs,
          logger: logger,
          os: osUtils,
          platform: FakePlatform(
            operatingSystem: 'windows',
            environment: const <String, String>{'LOCALAPPDATA': r'C:\Users\user\AppData\Local'},
          ),
        ),
      );
      expect(
        withWindowsLocalAppData.artifactsCacheDirectory.path,
        r'C:\Users\user\AppData\Local\flutter_tool_extensions\artifacts',
      );

      final withWindowsUserProfile = ExtensionArtifactManager(
        extensionManager: manager,
        featureFlags: TestFeatureFlags(),
        toolContext: FakeToolContext(
          fs: windowsFs,
          logger: logger,
          os: osUtils,
          platform: FakePlatform(
            operatingSystem: 'windows',
            environment: const <String, String>{'USERPROFILE': r'C:\Users\user'},
          ),
        ),
      );
      expect(
        withWindowsUserProfile.artifactsCacheDirectory.path,
        r'C:\Users\user\.flutter_tool_extensions\artifacts',
      );

      final withNoEnv = ExtensionArtifactManager(
        extensionManager: manager,
        featureFlags: TestFeatureFlags(),
        toolContext: FakeToolContext(fs: fs, logger: logger, os: osUtils, platform: FakePlatform()),
      );
      expect(
        () => withNoEnv.artifactsCacheDirectory,
        throwsA(
          isA<ToolExit>().having(
            (ToolExit e) => e.message,
            'message',
            contains('Unable to determine shared cache directory for tool extension artifacts'),
          ),
        ),
      );
    });

    test('does nothing when tool extensions feature flag is disabled', () async {
      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
      );
      addTearDown(manager.dispose);
      final artifactManager = ExtensionArtifactManager(
        extensionManager: manager,
        featureFlags: TestFeatureFlags(),
        toolContext: FakeToolContext(
          fs: fs,
          logger: logger,
          os: osUtils,
          platform: FakePlatform(
            environment: const <String, String>{'DART_DATA_HOME': '/dart_data'},
          ),
        ),
      );

      await artifactManager.ensureArtifactsDownloaded();
      expect(manager.isInitialized, isFalse);
      expect(fs.directory('/dart_data').existsSync(), isFalse);
    });

    test('downloads and verifies artifact by SHA-256 into content-addressed cache and skips on cache hit', () async {
      final List<int> content = utf8.encode('custom binary payload');
      final contentSha256 = sha256.convert(content).toString();

      void entryPoint(SendPort sendPort) {
        ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[
            _FakeArtifactService(<ArtifactDependency>[
              ArtifactDependency.remote(
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
      addTearDown(manager.dispose);

      var downloadCount = 0;
      final httpClient = _FakeHttpClient((Uri url) async {
        downloadCount++;
        return _FakeHttpClientResponse(HttpStatus.ok, content);
      });

      final artifactManager = ExtensionArtifactManager(
        extensionManager: manager,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        httpClient: httpClient,
        toolContext: FakeToolContext(
          fs: fs,
          logger: logger,
          os: osUtils,
          platform: FakePlatform(
            environment: const <String, String>{'DART_DATA_HOME': '/dart_data'},
          ),
        ),
      );

      final Map<String, String> resolved = await artifactManager.ensureArtifactsDownloaded(
        targetPlatforms: const <String>{'linux-x64'},
      );

      expect(downloadCount, 1);
      final File artifactFile = fs.file(
        '/dart_data/flutter_tool_extensions/artifacts/custom_ext/$contentSha256/my_custom_bin',
      );
      expect(resolved, <String, String>{'my_custom_bin': artifactFile.path});
      expect(artifactFile.existsSync(), isTrue);
      expect(artifactFile.readAsBytesSync(), equals(content));
      final File stampFile = fs.file(
        '/dart_data/flutter_tool_extensions/artifacts/custom_ext/$contentSha256/.my_custom_bin.sha256',
      );
      expect(stampFile.existsSync(), isTrue);
      expect(stampFile.readAsStringSync(), contentSha256);

      // Second call should verify SHA-256 and skip downloading.
      await artifactManager.ensureArtifactsDownloaded(targetPlatforms: const <String>{'linux-x64'});
      expect(downloadCount, 1);

      // Passing force: true should re-download even when cached and verified.
      await artifactManager.ensureArtifactsDownloaded(
        targetPlatforms: const <String>{'linux-x64'},
        force: true,
      );
      expect(downloadCount, 2);

      // Corrupt the cached stamp; next call should detect SHA-256 mismatch and re-download.
      artifactFile.writeAsStringSync('corrupted bytes');
      stampFile.writeAsStringSync(
        '0000000000000000000000000000000000000000000000000000000000000000',
      );
      await artifactManager.ensureArtifactsDownloaded(targetPlatforms: const <String>{'linux-x64'});
      expect(downloadCount, 3);
      expect(artifactFile.readAsBytesSync(), equals(content));
      expect(stampFile.readAsStringSync(), contentSha256);
    });

    test('unzips .zip artifacts into sha256-keyed directory and writes stamp file', () async {
      final List<int> zipContent = utf8.encode('fake zip archive bytes');
      final zipSha256 = sha256.convert(zipContent).toString();

      void entryPoint(SendPort sendPort) {
        ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[
            _FakeArtifactService(<ArtifactDependency>[
              ArtifactDependency.remote(
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
      addTearDown(manager.dispose);

      var downloadCount = 0;
      final httpClient = _FakeHttpClient((Uri url) async {
        downloadCount++;
        return _FakeHttpClientResponse(HttpStatus.ok, zipContent);
      });
      final unzipOsUtils = _UnzipTrackingOsUtils();

      final Directory customCacheDir = fs.directory('/custom/cache');
      final artifactManager = ExtensionArtifactManager(
        cacheDir: customCacheDir,
        extensionManager: manager,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        httpClient: httpClient,
        toolContext: FakeToolContext(
          cache: FakeCache(engineRevision: 'engine_rev_123', fileSystem: fs),
          fs: fs,
          logger: logger,
          os: unzipOsUtils,
          platform: FakePlatform(),
        ),
      );

      final Map<String, String> resolved = await artifactManager.ensureArtifactsDownloaded(
        targetPlatforms: const <String>{'custom-embedder-arm64'},
      );

      expect(downloadCount, 1);
      expect(unzipOsUtils.unzipCount, 1);
      final Directory destDir = customCacheDir
          .childDirectory('embedder_ext')
          .childDirectory(zipSha256);
      final Directory extractedDir = destDir.childDirectory('engine_bundle');
      final File stampFile = destDir.childFile('.engine_bundle.sha256');
      expect(resolved, <String, String>{'engine_bundle': extractedDir.path});
      expect(extractedDir.existsSync(), isTrue);
      expect(extractedDir.childFile('extracted.txt').existsSync(), isTrue);
      expect(stampFile.existsSync(), isTrue);
      expect(stampFile.readAsStringSync(), zipSha256);

      // Subsequent call hits verified stamp and does not re-download.
      await artifactManager.ensureArtifactsDownloaded(
        targetPlatforms: const <String>{'custom-embedder-arm64'},
      );
      expect(downloadCount, 1);
      expect(unzipOsUtils.unzipCount, 1);
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
                ArtifactDependency.remote(
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
        addTearDown(manager.dispose);

        await manager.ensureInitialized();

        var downloadCount = 0;
        final downloadStarted = Completer<void>();
        final releaseDownload = Completer<void>();
        final httpClient = _FakeHttpClient((Uri url) async {
          downloadCount++;
          if (!downloadStarted.isCompleted) {
            downloadStarted.complete();
          }
          await releaseDownload.future;
          return _FakeHttpClientResponse(HttpStatus.ok, content);
        });

        final Directory cacheDir = fs.directory('/concurrent_cache');
        final artifactManager = ExtensionArtifactManager(
          cacheDir: cacheDir,
          extensionManager: manager,
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
          httpClient: httpClient,
          toolContext: FakeToolContext(
            fs: fs,
            logger: logger,
            os: osUtils,
            platform: FakePlatform(),
          ),
        );

        final Future<Map<String, String>> call1 = artifactManager.ensureArtifactsDownloaded();
        await downloadStarted.future;
        final Future<Map<String, String>> call2 = artifactManager.ensureArtifactsDownloaded();
        final Future<Map<String, String>> call3 = artifactManager.ensureArtifactsDownloaded();
        await pumpEventQueue();
        releaseDownload.complete();

        await Future.wait(<Future<Map<String, String>>>[call1, call2, call3]);

        expect(downloadCount, 1);
        final File cachedFile = cacheDir
            .childDirectory('concurrent_ext')
            .childDirectory(contentSha256)
            .childFile('concurrent_bin');
        expect(cachedFile.existsSync(), isTrue);
        expect(cachedFile.readAsBytesSync(), equals(content));
      },
    );

    test('throws ToolExit when SHA-256 checksum mismatches or network fails', () async {
      final List<int> content = utf8.encode('corrupted payload');

      void entryPoint(SendPort sendPort) {
        ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[
            _FakeArtifactService(<ArtifactDependency>[
              ArtifactDependency.remote(
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
      addTearDown(manager.dispose);

      final httpClient = _FakeHttpClient(
        (Uri url) async => _FakeHttpClientResponse(HttpStatus.ok, content),
      );

      final artifactManager = ExtensionArtifactManager(
        cacheDir: fs.directory('/bad_cache'),
        extensionManager: manager,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        httpClient: httpClient,
        toolContext: FakeToolContext(fs: fs, logger: logger, os: osUtils, platform: FakePlatform()),
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

      final failingNetworkClient = _FakeHttpClient(
        (Uri url) async => throw const SocketException('Connection refused'),
      );
      final networkErrorManager = ExtensionArtifactManager(
        cacheDir: fs.directory('/bad_network_cache'),
        extensionManager: manager,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        httpClient: failingNetworkClient,
        toolContext: FakeToolContext(fs: fs, logger: logger, os: osUtils, platform: FakePlatform()),
      );

      await expectLater(
        networkErrorManager.ensureArtifactsDownloaded(),
        throwsA(
          isA<ToolExit>().having(
            (ToolExit e) => e.message,
            'message',
            contains('Failed to download artifact "bad_bin"'),
          ),
        ),
      );
    });

    test('works with LinuxArtifactService prototype extension', () async {
      const content = <int>[]; // Empty bytes match e3b0c44298fc...
      const expectedSha = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

      void configuredLinuxEntryPoint(SendPort sendPort) {
        ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[
            LinuxArtifactService(
              artifacts: <ArtifactDependency>[
                ArtifactDependency.remote(
                  name: 'linux-x64-custom-artifact',
                  sha256: expectedSha,
                  url: Uri.parse('https://example.com/linux-x64/artifacts'),
                  hostPlatform: HostPlatform.linux_x64,
                  targetPlatform: 'linux-x64',
                ),
              ],
            ),
          ],
          extensionName: 'flutter_tools_extension_linux_prototype',
          supportedPlatforms: const <String>{'linux'},
        );
      }

      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        entryPoints: <ExtensionEntryPoint>[configuredLinuxEntryPoint],
      );
      addTearDown(manager.dispose);

      final Directory cacheDir = fs.directory('/shared_cache');
      final Directory destDir = cacheDir
          .childDirectory('flutter_tools_extension_linux_prototype')
          .childDirectory(expectedSha);
      destDir.childFile('linux-x64-custom-artifact')
        ..createSync(recursive: true)
        ..writeAsBytesSync(content);
      destDir.childFile('.linux-x64-custom-artifact.sha256')
        ..createSync(recursive: true)
        ..writeAsStringSync(expectedSha);

      var downloadTriggered = false;
      final httpClient = _FakeHttpClient((Uri url) async {
        downloadTriggered = true;
        return _FakeHttpClientResponse(HttpStatus.ok, content);
      });

      final artifactManager = ExtensionArtifactManager(
        cacheDir: cacheDir,
        extensionManager: manager,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        httpClient: httpClient,
        toolContext: FakeToolContext(fs: fs, logger: logger, os: osUtils, platform: FakePlatform()),
      );

      await artifactManager.ensureArtifactsDownloaded(targetPlatforms: const <String>{'linux'});
      expect(downloadTriggered, isFalse);
    });

    test(
      'forwards multiple targetPlatforms to ArtifactService and filters matching artifacts',
      () async {
        final List<int> content = utf8.encode('multi-target payload');
        final contentSha256 = sha256.convert(content).toString();
        final targetPlatformsPort = ReceivePort();
        addTearDown(targetPlatformsPort.close);

        final ExtensionEntryPoint entryPoint = _createMultiTargetEntryPoint(
          artifacts: <ArtifactDependency>[
            ArtifactDependency.remote(
              name: 'linux_bin',
              sha256: contentSha256,
              url: Uri.parse('https://example.com/linux_bin'),
              hostPlatform: HostPlatform.linux_x64,
              targetPlatform: 'linux-x64',
            ),
            ArtifactDependency.remote(
              name: 'embedder_bin',
              sha256: contentSha256,
              url: Uri.parse('https://example.com/embedder_bin'),
              hostPlatform: HostPlatform.linux_x64,
              targetPlatform: 'custom-embedder-arm64',
            ),
            ArtifactDependency.remote(
              name: 'unselected_bin',
              sha256: contentSha256,
              url: Uri.parse('https://example.com/unselected_bin'),
              hostPlatform: HostPlatform.linux_x64,
              targetPlatform: 'other-platform',
            ),
          ],
          targetPlatformsObserver: targetPlatformsPort.sendPort,
        );

        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
          entryPoints: <ExtensionEntryPoint>[entryPoint],
        );
        addTearDown(manager.dispose);

        final downloadedUrls = <Uri>[];
        final httpClient = _FakeHttpClient((Uri url) async {
          downloadedUrls.add(url);
          return _FakeHttpClientResponse(HttpStatus.ok, content);
        });

        final Directory cacheDir = fs.directory('/multi_cache');
        final artifactManager = ExtensionArtifactManager(
          cacheDir: cacheDir,
          extensionManager: manager,
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
          httpClient: httpClient,
          toolContext: FakeToolContext(
            fs: fs,
            logger: logger,
            os: osUtils,
            platform: FakePlatform(),
          ),
        );

        await artifactManager.ensureArtifactsDownloaded(
          targetPlatforms: const <String>{'linux', 'custom-embedder-arm64'},
        );

        expect(
          await targetPlatformsPort.first,
          unorderedEquals(<String>['linux', 'custom-embedder-arm64']),
        );
        expect(downloadedUrls, <Uri>[
          Uri.parse('https://example.com/linux_bin'),
          Uri.parse('https://example.com/embedder_bin'),
        ]);
      },
    );

    test('isolates same-named artifacts across extensions on precache and scopes resolution by extensionName, while warning on intra-extension duplicates', () async {
      final List<int> ext1Content = utf8.encode('ext1 artifact payload');
      final ext1Sha256 = sha256.convert(ext1Content).toString();
      final List<int> ext2Content = utf8.encode('ext2 artifact payload');
      final ext2Sha256 = sha256.convert(ext2Content).toString();

      void firstEntryPoint(SendPort sendPort) {
        ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[
            _FakeArtifactService(<ArtifactDependency>[
              ArtifactDependency.remote(
                name: 'shared_bin',
                sha256: ext1Sha256,
                url: Uri.parse('https://example.com/ext1/shared_bin'),
                hostPlatform: HostPlatform.linux_x64,
              ),
              ArtifactDependency.remote(
                name: 'shared_bin',
                sha256: ext2Sha256,
                url: Uri.parse('https://example.com/ext1/duplicate_shared_bin'),
                hostPlatform: HostPlatform.linux_x64,
              ),
            ]),
          ],
          extensionName: 'first_ext',
          supportedPlatforms: const <String>{'linux'},
        );
      }

      void secondEntryPoint(SendPort sendPort) {
        ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[
            _FakeArtifactService(<ArtifactDependency>[
              ArtifactDependency.remote(
                name: 'shared_bin',
                sha256: ext2Sha256,
                url: Uri.parse('https://example.com/ext2/shared_bin'),
                hostPlatform: HostPlatform.linux_x64,
              ),
            ]),
          ],
          extensionName: 'second_ext',
          supportedPlatforms: const <String>{'linux'},
        );
      }

      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        entryPoints: <ExtensionEntryPoint>[firstEntryPoint, secondEntryPoint],
      );
      addTearDown(manager.dispose);

      final downloadedUrls = <Uri>[];
      final httpClient = _FakeHttpClient((Uri url) async {
        downloadedUrls.add(url);
        final payload = url.path.contains('/ext2/') ? ext2Content : ext1Content;
        return _FakeHttpClientResponse(HttpStatus.ok, payload);
      });

      final Directory cacheDir = fs.directory('/collision_cache');
      final artifactManager = ExtensionArtifactManager(
        cacheDir: cacheDir,
        extensionManager: manager,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        httpClient: httpClient,
        toolContext: FakeToolContext(fs: fs, logger: logger, os: osUtils, platform: FakePlatform()),
      );

      // Precache (`extensionName: null`) downloads both extensions' artifacts into
      // their own extension-scoped cache directories while skipping the duplicate
      // declaration inside `first_ext`.
      await artifactManager.ensureArtifactsDownloaded();
      expect(downloadedUrls, <Uri>[
        Uri.parse('https://example.com/ext1/shared_bin'),
        Uri.parse('https://example.com/ext2/shared_bin'),
      ]);
      expect(
        logger.warningText,
        contains(
          'Extension "first_ext" declared duplicate artifact "shared_bin"; '
          'keeping the first declaration.',
        ),
      );
      expect(
        fs.file('/collision_cache/first_ext/$ext1Sha256/shared_bin').readAsBytesSync(),
        equals(ext1Content),
      );
      expect(
        fs.file('/collision_cache/second_ext/$ext2Sha256/shared_bin').readAsBytesSync(),
        equals(ext2Content),
      );

      // Per-extension resolution returns each extension's own cached path without re-downloading.
      final Map<String, String> firstResolved = await artifactManager.ensureArtifactsDownloaded(
        extensionName: 'first_ext',
      );
      final Map<String, String> secondResolved = await artifactManager.ensureArtifactsDownloaded(
        extensionName: 'second_ext',
      );
      expect(firstResolved, <String, String>{
        'shared_bin': '/collision_cache/first_ext/$ext1Sha256/shared_bin',
      });
      expect(secondResolved, <String, String>{
        'shared_bin': '/collision_cache/second_ext/$ext2Sha256/shared_bin',
      });
      expect(downloadedUrls, hasLength(2));
    });

    test('applies chmod a+x for isExecutable single-file artifacts and validated zip executables, and rejects missing or symlinked executables', () async {
      final List<int> binContent = utf8.encode('#!/bin/sh\necho hi\n');
      final binSha256 = sha256.convert(binContent).toString();
      final List<int> zipContent = utf8.encode('fake toolchain zip');
      final zipSha256 = sha256.convert(zipContent).toString();

      void execEntryPoint(SendPort sendPort) {
        ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[
            _FakeArtifactService(<ArtifactDependency>[
              ArtifactDependency.remote(
                name: 'standalone_tool',
                sha256: binSha256,
                url: Uri.parse('https://example.com/standalone_tool'),
                isExecutable: true,
                hostPlatform: HostPlatform.linux_x64,
              ),
              ArtifactDependency.remote(
                name: 'data_blob',
                sha256: binSha256,
                url: Uri.parse('https://example.com/data_blob'),
                hostPlatform: HostPlatform.linux_x64,
              ),
              ArtifactDependency.remote(
                name: 'toolchain_bundle',
                sha256: zipSha256,
                url: Uri.parse('https://example.com/toolchain_bundle.zip'),
                executables: const <String>{'gen_snapshot', 'bin/ld.lld'},
                hostPlatform: HostPlatform.linux_x64,
              ),
            ]),
          ],
          extensionName: 'exec_ext',
          supportedPlatforms: const <String>{'linux'},
        );
      }

      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        entryPoints: <ExtensionEntryPoint>[execEntryPoint],
      );
      addTearDown(manager.dispose);

      final httpClient = _FakeHttpClient((Uri url) async {
        final payload = url.path.endsWith('.zip') ? zipContent : binContent;
        return _FakeHttpClientResponse(HttpStatus.ok, payload);
      });
      final execOsUtils = _UnzipTrackingOsUtils(
        extractedFiles: const <String>['gen_snapshot', 'bin/ld.lld', 'include/header.h'],
      );

      final Directory cacheDir = fs.directory('/exec_cache');
      final artifactManager = ExtensionArtifactManager(
        cacheDir: cacheDir,
        extensionManager: manager,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        httpClient: httpClient,
        toolContext: FakeToolContext(
          fs: fs,
          logger: logger,
          os: execOsUtils,
          platform: FakePlatform(),
        ),
      );

      final Map<String, String> resolved = await artifactManager.ensureArtifactsDownloaded(
        extensionName: 'exec_ext',
      );
      expect(resolved['standalone_tool'], '/exec_cache/exec_ext/$binSha256/standalone_tool');
      expect(resolved['toolchain_bundle'], '/exec_cache/exec_ext/$zipSha256/toolchain_bundle');

      // `standalone_tool`, `gen_snapshot`, and `bin/ld.lld` were chmodded `a+x`
      // (while `data_blob` and `include/header.h` were not).
      expect(execOsUtils.chmods, hasLength(3));
      expect(
        execOsUtils.chmods.map((List<String> c) => c[1]).toSet(),
        equals(const <String>{'a+x'}),
      );
      expect(
        execOsUtils.chmods.map((List<String> c) => fs.path.basename(c[0])),
        unorderedEquals(<String>['standalone_tool', 'gen_snapshot', 'ld.lld']),
      );

      // Missing declared executable in zip throws ToolExit without writing cache or stamp.
      void missingExecEntryPoint(SendPort sendPort) {
        ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[
            _FakeArtifactService(<ArtifactDependency>[
              ArtifactDependency.remote(
                name: 'broken_bundle',
                sha256: zipSha256,
                url: Uri.parse('https://example.com/broken_bundle.zip'),
                executables: const <String>{'missing_gen_snapshot'},
                hostPlatform: HostPlatform.linux_x64,
              ),
            ]),
          ],
          extensionName: 'missing_exec_ext',
          supportedPlatforms: const <String>{'linux'},
        );
      }

      final missingManager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        entryPoints: <ExtensionEntryPoint>[missingExecEntryPoint],
      );
      addTearDown(missingManager.dispose);

      final missingArtifactManager = ExtensionArtifactManager(
        cacheDir: cacheDir,
        extensionManager: missingManager,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        httpClient: httpClient,
        toolContext: FakeToolContext(
          fs: fs,
          logger: logger,
          os: _UnzipTrackingOsUtils(),
          platform: FakePlatform(),
        ),
      );
      await expectLater(
        missingArtifactManager.ensureArtifactsDownloaded(),
        throwsA(
          isA<ToolExit>().having(
            (ToolExit e) => e.message,
            'message',
            contains('Executable "missing_gen_snapshot" declared by artifact "broken_bundle"'),
          ),
        ),
      );
      expect(
        cacheDir
            .childDirectory('missing_exec_ext')
            .childDirectory(zipSha256)
            .childDirectory('broken_bundle')
            .existsSync(),
        isFalse,
      );
      expect(
        cacheDir
            .childDirectory('missing_exec_ext')
            .childDirectory(zipSha256)
            .childFile('.broken_bundle.sha256')
            .existsSync(),
        isFalse,
      );

      // Symlinked executable or symlinked intermediate directory throws ToolExit.
      for (final symlinkCase in <({bool linkParentDir, String expectedMessage})>[
        (
          linkParentDir: false,
          expectedMessage: 'Executable "bin/gen_snapshot" in artifact "symlink_bundle" for extension "symlink_ext" must not be a symbolic link.',
        ),
        (
          linkParentDir: true,
          expectedMessage: 'Executable "bin/gen_snapshot" in artifact "symlink_bundle" for extension "symlink_ext" traverses a symbolic link.',
        ),
      ]) {
        void symlinkEntryPoint(SendPort sendPort) {
          ToolExtensionEntryPoint.run(
            sendPort,
            <ToolExtensionService>[
              _FakeArtifactService(<ArtifactDependency>[
                ArtifactDependency.remote(
                  name: 'symlink_bundle',
                  sha256: zipSha256,
                  url: Uri.parse('https://example.com/symlink_bundle.zip'),
                  executables: const <String>{'bin/gen_snapshot'},
                  hostPlatform: HostPlatform.linux_x64,
                ),
              ]),
            ],
            extensionName: 'symlink_ext',
            supportedPlatforms: const <String>{'linux'},
          );
        }

        final symlinkManager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
          entryPoints: <ExtensionEntryPoint>[symlinkEntryPoint],
        );
        addTearDown(symlinkManager.dispose);

        final symlinkOsUtils = _UnzipTrackingOsUtils(
          customUnzip: (Directory targetDir) {
            fs.file('/outside/gen_snapshot')
              ..createSync(recursive: true)
              ..writeAsStringSync('outside');
            if (symlinkCase.linkParentDir) {
              targetDir.childLink('bin').createSync('/outside', recursive: true);
            } else {
              targetDir.childDirectory('bin').createSync(recursive: true);
              targetDir
                  .childDirectory('bin')
                  .childLink('gen_snapshot')
                  .createSync('/outside/gen_snapshot');
            }
          },
        );
        final symlinkArtifactManager = ExtensionArtifactManager(
          cacheDir: cacheDir,
          extensionManager: symlinkManager,
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
          httpClient: httpClient,
          toolContext: FakeToolContext(
            fs: fs,
            logger: logger,
            os: symlinkOsUtils,
            platform: FakePlatform(),
          ),
        );
        await expectLater(
          symlinkArtifactManager.ensureArtifactsDownloaded(),
          throwsA(
            isA<ToolExit>().having(
              (ToolExit e) => e.message,
              'message',
              contains(symlinkCase.expectedMessage),
            ),
          ),
        );
        expect(symlinkOsUtils.chmods, isEmpty);
      }
    });

    test('resolves LocalArtifactDependency directly on disk and throws ToolExit when localUri or stampUri is missing', () async {
      final File localEngineBin = fs.file('/local/engine/out/host_debug_unopt/gen_snapshot')
        ..createSync(recursive: true)
        ..writeAsStringSync('local gen_snapshot binary');
      final Directory localEngineDir = fs.directory('/local/engine/out/host_debug_unopt')
        ..createSync(recursive: true);
      final File localEngineStamp = localEngineDir.childFile('.stamp')
        ..createSync(recursive: true)
        ..writeAsStringSync('stamp_v1');

      void localEntryPoint(SendPort sendPort) {
        ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[
            _FakeArtifactService(<ArtifactDependency>[
              ArtifactDependency.local(
                name: 'local_gen_snapshot',
                localUri: localEngineBin.uri,
                hostPlatform: HostPlatform.linux_x64,
                targetPlatform: 'custom-embedder-arm64',
              ),
              ArtifactDependency.local(
                name: 'local_engine_dir',
                localUri: localEngineDir.uri,
                stampUri: localEngineStamp.uri,
                hostPlatform: HostPlatform.linux_x64,
                targetPlatform: 'custom-embedder-arm64',
              ),
            ]),
          ],
          extensionName: 'local_ext',
          supportedPlatforms: const <String>{'linux'},
        );
      }

      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        entryPoints: <ExtensionEntryPoint>[localEntryPoint],
      );
      addTearDown(manager.dispose);

      var downloadCount = 0;
      final httpClient = _FakeHttpClient((Uri url) async {
        downloadCount++;
        return _FakeHttpClientResponse(HttpStatus.ok, const <int>[]);
      });

      final Directory cacheDir = fs.directory('/unused_cache');
      final artifactManager = ExtensionArtifactManager(
        cacheDir: cacheDir,
        extensionManager: manager,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        httpClient: httpClient,
        toolContext: FakeToolContext(fs: fs, logger: logger, os: osUtils, platform: FakePlatform()),
      );

      final Map<String, String> resolved = await artifactManager.ensureArtifactsDownloaded(
        targetPlatforms: const <String>{'custom-embedder-arm64'},
      );
      expect(downloadCount, 0);
      expect(cacheDir.existsSync(), isFalse);
      expect(resolved, <String, String>{
        'local_gen_snapshot': '/local/engine/out/host_debug_unopt/gen_snapshot',
        'local_engine_dir': '/local/engine/out/host_debug_unopt',
      });

      // Deleting the stamp file should cause resolution to fail with ToolExit.
      localEngineStamp.deleteSync();
      await expectLater(
        artifactManager.ensureArtifactsDownloaded(
          targetPlatforms: const <String>{'custom-embedder-arm64'},
        ),
        throwsA(
          isA<ToolExit>().having(
            (ToolExit e) => e.message,
            'message',
            contains(
              'Stamp file for local artifact "local_engine_dir" for extension "local_ext" was not found at "/local/engine/out/host_debug_unopt/.stamp".',
            ),
          ),
        ),
      );

      // Deleting the local artifact file should also fail with ToolExit.
      localEngineStamp.writeAsStringSync('stamp_v2');
      localEngineBin.deleteSync();
      await expectLater(
        artifactManager.ensureArtifactsDownloaded(
          targetPlatforms: const <String>{'custom-embedder-arm64'},
        ),
        throwsA(
          isA<ToolExit>().having(
            (ToolExit e) => e.message,
            'message',
            contains(
              'Local artifact "local_gen_snapshot" for extension "local_ext" was not found at "/local/engine/out/host_debug_unopt/gen_snapshot".',
            ),
          ),
        ),
      );
    });
  });
}

class _UnzipTrackingOsUtils extends FakeOperatingSystemUtils {
  _UnzipTrackingOsUtils({this.customUnzip, this.extractedFiles = const <String>['extracted.txt']});

  final void Function(Directory targetDirectory)? customUnzip;
  final List<String> extractedFiles;
  int unzipCount = 0;

  @override
  void unzip(File file, Directory targetDirectory) {
    unzipCount++;
    if (customUnzip case final void Function(Directory) callback) {
      callback(targetDirectory);
      return;
    }
    for (final String relativePath in extractedFiles) {
      targetDirectory.fileSystem.file(
          targetDirectory.fileSystem.path.joinAll(<String>[
            targetDirectory.path,
            ...relativePath.split('/'),
          ]),
        )
        ..createSync(recursive: true)
        ..writeAsStringSync('extracted');
    }
  }
}

class _FakeHttpClient extends Fake implements HttpClient {
  _FakeHttpClient(this._handler);

  final Future<_FakeHttpClientResponse> Function(Uri url) _handler;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest(url, _handler);
}

class _FakeHttpClientRequest extends Fake implements HttpClientRequest {
  _FakeHttpClientRequest(this._url, this._handler);

  final Uri _url;
  final Future<_FakeHttpClientResponse> Function(Uri url) _handler;

  @override
  Future<HttpClientResponse> close() => _handler(_url);
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
