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
  _FakeArtifactService(this.artifacts);

  final List<ArtifactDependency> artifacts;

  @override
  Future<List<ArtifactDependency>> downloadArtifacts({
    required String engineVersion,
    required HostPlatform hostPlatform,
    Set<String>? targetPlatforms,
  }) async {
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
        '/dart_data/flutter_tool_extensions/artifacts/custom_ext/fake_engine_revision/my_custom_bin',
      );
      expect(resolved, <String, String>{'my_custom_bin': artifactFile.path});
      expect(artifactFile.existsSync(), isTrue);
      expect(artifactFile.readAsBytesSync(), equals(content));
      final File stampFile = fs.file(
        '/dart_data/flutter_tool_extensions/artifacts/custom_ext/fake_engine_revision/.my_custom_bin.sha256',
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

      // Corrupt the cached file; next call should detect SHA-256 mismatch and re-download.
      artifactFile.writeAsStringSync('corrupted bytes');
      await artifactManager.ensureArtifactsDownloaded(targetPlatforms: const <String>{'linux-x64'});
      expect(downloadCount, 3);
      expect(artifactFile.readAsBytesSync(), equals(content));
    });

    test(
      'unzips .zip artifacts into engineVersion-keyed directory and writes stamp file',
      () async {
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
        final Directory engineDir = customCacheDir
            .childDirectory('embedder_ext')
            .childDirectory('engine_rev_123');
        final Directory extractedDir = engineDir.childDirectory('engine_bundle');
        final File stampFile = engineDir.childFile('.engine_bundle.sha256');
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
      },
    );

    test(
      'fetches sha256Url on cache miss and verifies offline via stamp file on cache hit',
      () async {
        final List<int> content = utf8.encode('remote checksummed binary');
        final contentSha256 = sha256.convert(content).toString();
        final Uri artifactUri = Uri.parse('https://example.com/remote_bin');
        final Uri sha256Uri = Uri.parse('https://example.com/remote_bin.sha256sum');

        void entryPoint(SendPort sendPort) {
          ToolExtensionEntryPoint.run(
            sendPort,
            <ToolExtensionService>[
              _FakeArtifactService(<ArtifactDependency>[
                ArtifactDependency(
                  name: 'remote_bin',
                  sha256Url: sha256Uri,
                  url: artifactUri,
                  hostPlatform: HostPlatform.linux_x64,
                ),
              ]),
            ],
            extensionName: 'sha_url_ext',
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

        var shaFetchCount = 0;
        var artifactFetchCount = 0;
        var failNetwork = false;
        final httpClient = _FakeHttpClient((Uri url) async {
          if (failNetwork) {
            throw const SocketException('Offline');
          }
          if (url == sha256Uri) {
            shaFetchCount++;
            return _FakeHttpClientResponse(
              HttpStatus.ok,
              utf8.encode('${contentSha256.toUpperCase()}  remote_bin\n'),
            );
          }
          if (url == artifactUri) {
            artifactFetchCount++;
            return _FakeHttpClientResponse(HttpStatus.ok, content);
          }
          return _FakeHttpClientResponse(HttpStatus.notFound, const <int>[]);
        });

        final Directory cacheDir = fs.directory('/sha_url_cache');
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

        final Map<String, String> resolved = await artifactManager.ensureArtifactsDownloaded();
        expect(shaFetchCount, 1);
        expect(artifactFetchCount, 1);
        final File cachedFile = cacheDir
            .childDirectory('sha_url_ext')
            .childDirectory('fake_engine_revision')
            .childFile('remote_bin');
        expect(resolved, <String, String>{'remote_bin': cachedFile.path});
        expect(cachedFile.existsSync(), isTrue);

        // Subsequent call while offline should verify against local .sha256 stamp without fetching sha256Url.
        failNetwork = true;
        final Map<String, String> cachedResolved = await artifactManager
            .ensureArtifactsDownloaded();
        expect(cachedResolved, <String, String>{'remote_bin': cachedFile.path});
        expect(shaFetchCount, 1);
        expect(artifactFetchCount, 1);

        // Corrupting the file triggers re-fetching sha256Url and artifact when online.
        failNetwork = false;
        cachedFile.writeAsStringSync('tampered');
        await artifactManager.ensureArtifactsDownloaded();
        expect(shaFetchCount, 2);
        expect(artifactFetchCount, 2);
        expect(cachedFile.readAsBytesSync(), equals(content));
      },
    );

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
        releaseDownload.complete();

        await Future.wait(<Future<Map<String, String>>>[call1, call2, call3]);

        expect(downloadCount, 1);
        final File cachedFile = cacheDir
            .childDirectory('concurrent_ext')
            .childDirectory('fake_engine_revision')
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
                ArtifactDependency(
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
      final Directory engineDir = cacheDir
          .childDirectory('flutter_tools_extension_linux_prototype')
          .childDirectory('fake_engine_revision');
      engineDir.childFile('linux-x64-custom-artifact')
        ..createSync(recursive: true)
        ..writeAsBytesSync(content);

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

        void entryPoint(SendPort sendPort) {
          ToolExtensionEntryPoint.run(
            sendPort,
            <ToolExtensionService>[
              _FakeArtifactService(<ArtifactDependency>[
                ArtifactDependency(
                  name: 'linux_bin',
                  sha256: contentSha256,
                  url: Uri.parse('https://example.com/linux_bin'),
                  hostPlatform: HostPlatform.linux_x64,
                  targetPlatform: 'linux-x64',
                ),
                ArtifactDependency(
                  name: 'embedder_bin',
                  sha256: contentSha256,
                  url: Uri.parse('https://example.com/embedder_bin'),
                  hostPlatform: HostPlatform.linux_x64,
                  targetPlatform: 'custom-embedder-arm64',
                ),
                ArtifactDependency(
                  name: 'unselected_bin',
                  sha256: contentSha256,
                  url: Uri.parse('https://example.com/unselected_bin'),
                  hostPlatform: HostPlatform.linux_x64,
                  targetPlatform: 'other-platform',
                ),
              ]),
            ],
            extensionName: 'multi_ext',
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

        expect(downloadedUrls, <Uri>[
          Uri.parse('https://example.com/linux_bin'),
          Uri.parse('https://example.com/embedder_bin'),
        ]);
      },
    );
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
