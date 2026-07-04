// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:args/command_runner.dart';
import 'package:file/local.dart' as local_fs;
import 'package:file/memory.dart';
import 'package:flutter_tools/flutter_tools_extension.dart' as tool_extension;
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/create.dart';
import 'package:flutter_tools/src/experimental/templates.dart';
import 'package:flutter_tools/src/extension_prototypes/linux_extension/template.dart';
import 'package:flutter_tools/src/flutter_tools_core/templates.dart' as core;
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as rpc;
import 'package:stream_channel/isolate_channel.dart';
import 'package:test/fake.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/test_flutter_command_runner.dart';

void main() {
  setUpAll(() {
    Cache.disableLocking();
  });

  group('Linux Template Service (Extension Side)', () {
    testWithoutContext('LinuxTemplateService exposes custom-linux-app template', () async {
      final templateService = LinuxTemplateService();

      expect(templateService.namespace, 'template');
      expect(templateService.appPlatformTemplates, isEmpty);
      expect(templateService.pluginPlatformTemplates, isEmpty);
      expect(templateService.projectTemplates, hasLength(1));

      final tool_extension.ProjectTemplate template = templateService.projectTemplates.first;
      expect(template.name, 'custom-linux-app');
      expect(template.hidden, isFalse);
      expect(
        template.templatePath,
        contains('extension_prototypes/linux_extension/templates/custom-linux-app'),
      );
      expect(template.templateSources, contains('pubspec.yaml.tmpl'));
      expect(template.templateSources, contains('lib/main.dart.tmpl'));
      expect(template.templateSources, contains('.custom_device_extension_info.copy.tmpl'));

      final Map<String, Object?> params = await template.generateTemplateParameters(
        <String, Object?>{'foo': 'bar'},
      );
      expect(params, equals(<String, Object?>{'foo': 'bar'}));
    });

    testWithoutContext('TemplateService RPC handlers register and respond correctly', () async {
      final templateService = LinuxTemplateService();
      final Map<String, Function> rpcHandlers = await templateService.initialize();

      expect(rpcHandlers.containsKey('getAppTemplates'), isTrue);
      expect(rpcHandlers.containsKey('getPluginTemplates'), isTrue);
      expect(rpcHandlers.containsKey('getProjectTemplates'), isTrue);
      expect(rpcHandlers.containsKey('generateTemplateParameters'), isTrue);

      final getAppTemplates = rpcHandlers['getAppTemplates']! as Future<dynamic> Function();
      final getPluginTemplates = rpcHandlers['getPluginTemplates']! as Future<dynamic> Function();
      final getProjectTemplates = rpcHandlers['getProjectTemplates']! as Future<dynamic> Function();
      final generateTemplateParameters =
          rpcHandlers['generateTemplateParameters']!
              as Future<dynamic> Function(Map<String, Object?>);

      expect(await getAppTemplates(), isEmpty);
      expect(await getPluginTemplates(), isEmpty);

      final projectTemplates = await getProjectTemplates() as List<dynamic>;
      expect(projectTemplates, hasLength(1));
      final Map<String, Object?> templateMap = (projectTemplates.first as Map<Object?, Object?>)
          .cast<String, Object?>();
      expect(templateMap['name'], 'custom-linux-app');
      expect(
        templateMap['templatePath'],
        contains('extension_prototypes/linux_extension/templates/custom-linux-app'),
      );

      final paramsResult =
          await generateTemplateParameters(<String, Object?>{
                'templateName': 'custom-linux-app',
                'toolParameters': <String, String>{'projectName': 'my_app'},
              })
              as Map<String, dynamic>;
      expect(paramsResult['projectName'], 'my_app');
    });
  });

  group('ExtensionTemplateManager (Host Side)', () {
    testUsingContext(
      'create --help includes custom-linux-app in --template allowed help after templates are fetched',
      () async {
        final createCommand = CreateCommand();
        createTestCommandRunner(createCommand);
        final ExtensionTemplateManager templateManager = context.get<ExtensionTemplateManager>()!;

        expect(
          createCommand.argParser.options['template']!.allowedHelp!.containsKey('custom-linux-app'),
          isFalse,
        );

        await templateManager.getProjectTemplates();

        expect(
          createCommand.argParser.options['template']!.allowedHelp!.containsKey('custom-linux-app'),
          isTrue,
        );
        expect(
          createCommand.argParser.options['template']!.allowedHelp!['custom-linux-app'],
          'Generate a project using the custom-linux-app template.',
        );
      },
      overrides: <Type, Generator>{
        ProcessManager: () => FakeProcessManager.any(),
        Platform: () => FakePlatform(
          environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true', 'PATH': ''},
        ),
        ExtensionTemplateManager: () => MockExtensionTemplateManager(
          templates: <core.ProjectTemplate>[
            core.ExtensionProjectTemplate.fromJson(<String, Object?>{
              'name': 'custom-linux-app',
              'hidden': false,
              'templateDependencies': <String>[],
              'templateSources': <String>[
                'pubspec.yaml.tmpl',
                'lib/main.dart.tmpl',
                '.custom_device_extension_info.copy.tmpl',
              ],
              'templatePath':
                  'package:flutter_tools/src/extension_prototypes/linux_extension/templates/custom-linux-app',
            }),
          ],
          fileSystem: MemoryFileSystem.test(),
        ),
      },
    );

    testUsingContext(
      'FlutterCommandRunner queries getProjectTemplates prior to displaying create help',
      () async {
        final runner = FlutterCommandRunner();
        runner.addCommand(CreateCommand());
        final ExtensionTemplateManager templateManager = context.get<ExtensionTemplateManager>()!;

        expect(templateManager.cachedTemplates, isEmpty);

        await runner.run(<String>['create', '--help']);

        expect(templateManager.cachedTemplates, hasLength(1));
        expect(templateManager.cachedTemplates.first.name, 'custom-linux-app');
      },
      overrides: <Type, Generator>{
        ProcessManager: () => FakeProcessManager.any(),
        Platform: () => FakePlatform(
          environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true', 'PATH': ''},
        ),
        ExtensionTemplateManager: () => MockExtensionTemplateManager(
          templates: <core.ProjectTemplate>[
            core.ExtensionProjectTemplate.fromJson(<String, Object?>{
              'name': 'custom-linux-app',
              'hidden': false,
              'templateDependencies': <String>[],
              'templateSources': <String>[
                'pubspec.yaml.tmpl',
                'lib/main.dart.tmpl',
                '.custom_device_extension_info.copy.tmpl',
              ],
              'templatePath':
                  'package:flutter_tools/src/extension_prototypes/linux_extension/templates/custom-linux-app',
            }),
          ],
          fileSystem: MemoryFileSystem.test(),
        ),
      },
    );

    testUsingContext(
      'queries project templates and generates parameters',
      () async {
        final manager = tool_extension.ToolExtensionManager();

        final extensionReceivePort = ReceivePort();
        final Future<tool_extension.ToolExtension> extensionFuture = manager.connectExtension(
          extensionReceivePort,
        );

        final hostReceivePort = ReceivePort();
        extensionReceivePort.sendPort.send(hostReceivePort.sendPort);

        await extensionFuture;

        final testChannel = IsolateChannel<Object?>.connectReceive(hostReceivePort);
        final testPeer = rpc.Peer.withoutJson(testChannel);

        testPeer.registerMethod('extension.getCapabilities', () {
          return const tool_extension.ToolExtensionCapabilities(
            services: <String>['template'],
          ).toMap();
        });

        testPeer.registerMethod('template.getProjectTemplates', () {
          return <Map<String, Object?>>[
            <String, Object?>{
              'name': 'custom-linux-app',
              'hidden': false,
              'templateDependencies': <String>[],
              'templateSources': <String>[
                'pubspec.yaml.tmpl',
                'lib/main.dart.tmpl',
                '.custom_device_extension_info.copy.tmpl',
              ],
              'templatePath':
                  'package:flutter_tools/src/extension_prototypes/linux_extension/templates/custom-linux-app',
            },
          ];
        });

        testPeer.registerMethod('template.generateTemplateParameters', (rpc.Parameters params) {
          final String templateName = params['templateName'].asString;
          final Map<String, Object?> toolParameters = params['toolParameters'].asMap
              .cast<String, Object?>();
          if (templateName == 'custom-linux-app') {
            return <String, Object?>{...toolParameters, 'customKey': 'customValue'};
          }
          return toolParameters;
        });

        unawaited(testPeer.listen());

        final templateManager = ExtensionTemplateManager(extensionManager: manager);

        final List<core.ProjectTemplate> templates = await templateManager.getProjectTemplates();
        expect(templates, hasLength(1));
        expect(templates.first.name, 'custom-linux-app');
        expect(
          templates.first.templatePath,
          'package:flutter_tools/src/extension_prototypes/linux_extension/templates/custom-linux-app',
        );

        final Map<String, Object?> renderedParams = await templateManager
            .generateTemplateParameters('custom-linux-app', <String, Object?>{
              'projectName': 'test_project',
            });
        expect(renderedParams['projectName'], 'test_project');
        expect(renderedParams['customKey'], 'customValue');

        // Test resolve directory
        final Directory dir = templateManager.resolveTemplateDirectory(
          templates.first.templatePath,
        );
        expect(
          dir.path,
          endsWith(
            'packages/flutter_tools/lib/src/extension_prototypes/linux_extension/templates/custom-linux-app',
          ),
        );

        await manager.dispose();
        await testPeer.close();
        hostReceivePort.close();
        extensionReceivePort.close();
      },
      overrides: <Type, Generator>{
        Platform: () => FakePlatform(
          environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true', 'PATH': ''},
        ),
      },
    );
  });

  group('Flutter Create Command Integration (Hermetic)', () {
    late MemoryFileSystem memoryFileSystem;

    setUp(() {
      memoryFileSystem = MemoryFileSystem.test();
      _populatePubspecLock(memoryFileSystem);
    });

    testUsingContext(
      'renders custom template successfully',
      () async {
        final Directory templateDir = memoryFileSystem.directory(
          '/packages/flutter_tools/lib/src/extension_prototypes/linux_extension/templates/custom-linux-app',
        );
        templateDir.createSync(recursive: true);
        templateDir
            .childFile('pubspec.yaml.tmpl')
            .writeAsStringSync('name: {{projectName}}\nversion: 1.0.0');
        final Directory libDir = templateDir.childDirectory('lib');
        libDir.createSync(recursive: true);
        libDir.childFile('main.dart.tmpl').writeAsStringSync('void main() {}');
        templateDir
            .childFile('.custom_device_extension_info.copy.tmpl')
            .writeAsStringSync('Custom Linux Device Extension App Template Verified');

        final createCommand = CreateCommand();
        final CommandRunner<void> commandRunner = createTestCommandRunner(createCommand);

        final Directory outputDir = memoryFileSystem.directory('/my_project');
        expect(outputDir.existsSync(), isFalse);

        await commandRunner.run(<String>[
          'create',
          '--template=custom-linux-app',
          '--no-pub',
          outputDir.path,
        ]);

        expect(outputDir.existsSync(), isTrue);
        expect(outputDir.childFile('.custom_device_extension_info').existsSync(), isTrue);
        expect(
          outputDir.childFile('.custom_device_extension_info').readAsStringSync(),
          'Custom Linux Device Extension App Template Verified',
        );
        expect(
          outputDir.childFile('pubspec.yaml').readAsStringSync(),
          'name: my_project\nversion: 1.0.0',
        );
        expect(
          outputDir.childDirectory('lib').childFile('main.dart').readAsStringSync(),
          'void main() {}',
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => memoryFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Platform: () => FakePlatform(
          environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true', 'PATH': ''},
        ),
        ExtensionTemplateManager: () => MockExtensionTemplateManager(
          templates: <core.ProjectTemplate>[
            core.ExtensionProjectTemplate.fromJson(<String, Object?>{
              'name': 'custom-linux-app',
              'hidden': false,
              'templateDependencies': <String>[],
              'templateSources': <String>[
                'pubspec.yaml.tmpl',
                'lib/main.dart.tmpl',
                '.custom_device_extension_info.copy.tmpl',
              ],
              'templatePath':
                  'package:flutter_tools/src/extension_prototypes/linux_extension/templates/custom-linux-app',
            }),
          ],
          fileSystem: memoryFileSystem,
        ),
      },
    );
  });

  group('Flutter Create Command Integration (End-to-End Routing)', () {
    late tool_extension.ToolExtensionManager manager;
    late MemoryFileSystem memoryFileSystem;

    setUp(() {
      memoryFileSystem = MemoryFileSystem.test();
      _populatePubspecLock(memoryFileSystem);
    });

    testUsingContext(
      'queries extension and renders custom template',
      () async {
        manager = tool_extension.ToolExtensionManager();

        final extensionReceivePort = ReceivePort();
        final Future<tool_extension.ToolExtension> extensionFuture = manager.connectExtension(
          extensionReceivePort,
        );

        final hostReceivePort = ReceivePort();
        extensionReceivePort.sendPort.send(hostReceivePort.sendPort);

        await extensionFuture;

        final testChannel = IsolateChannel<Object?>.connectReceive(hostReceivePort);
        final testPeer = rpc.Peer.withoutJson(testChannel);

        testPeer.registerMethod('extension.getCapabilities', () {
          return const tool_extension.ToolExtensionCapabilities(
            services: <String>['template'],
          ).toMap();
        });

        testPeer.registerMethod('template.getProjectTemplates', () {
          return <Map<String, Object?>>[
            <String, Object?>{
              'name': 'custom-linux-app',
              'hidden': false,
              'templateDependencies': <String>[],
              'templateSources': <String>[
                'pubspec.yaml.tmpl',
                'lib/main.dart.tmpl',
                '.custom_device_extension_info.copy.tmpl',
              ],
              'templatePath':
                  'package:flutter_tools/src/extension_prototypes/linux_extension/templates/custom-linux-app',
            },
          ];
        });

        testPeer.registerMethod('template.generateTemplateParameters', (rpc.Parameters params) {
          final Map<String, Object?> toolParameters = params['toolParameters'].asMap
              .cast<String, Object?>();
          return toolParameters;
        });

        unawaited(testPeer.listen());

        // Create template source in memory FS
        final String templatePath = memoryFileSystem.path.join(
          Cache.flutterRoot!,
          'packages',
          'flutter_tools',
          'lib',
          'src',
          'extension_prototypes',
          'linux_extension',
          'templates',
          'custom-linux-app',
        );
        final Directory templateDir = memoryFileSystem.directory(templatePath);
        templateDir.createSync(recursive: true);
        templateDir
            .childFile('pubspec.yaml.tmpl')
            .writeAsStringSync('name: {{projectName}}\nversion: 1.0.0');
        final Directory libDir = templateDir.childDirectory('lib');
        libDir.createSync(recursive: true);
        libDir.childFile('main.dart.tmpl').writeAsStringSync('void main() {}');
        templateDir
            .childFile('.custom_device_extension_info.copy.tmpl')
            .writeAsStringSync('Custom Linux Device Extension App Template Verified');

        final createCommand = CreateCommand();
        final CommandRunner<void> commandRunner = createTestCommandRunner(createCommand);

        final Directory outputDir = memoryFileSystem.directory('/my_project');
        expect(outputDir.existsSync(), isFalse);

        // Pre-fetch templates in the manager to populate cache.
        // This is what would normally happen during runner setup.
        final ExtensionTemplateManager templateManager = context.get<ExtensionTemplateManager>()!;
        await templateManager.getProjectTemplates();

        await commandRunner.run(<String>[
          'create',
          '--template=custom-linux-app',
          '--no-pub',
          outputDir.path,
        ]);

        expect(outputDir.existsSync(), isTrue);
        expect(outputDir.childFile('.custom_device_extension_info').existsSync(), isTrue);
        expect(
          outputDir.childFile('.custom_device_extension_info').readAsStringSync(),
          'Custom Linux Device Extension App Template Verified',
        );

        await manager.dispose();
        await testPeer.close();
        hostReceivePort.close();
        extensionReceivePort.close();
      },
      overrides: <Type, Generator>{
        FileSystem: () => memoryFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Platform: () => FakePlatform(
          environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true', 'PATH': ''},
        ),
        tool_extension.ToolExtensionManager: () => manager,
        ExtensionTemplateManager: () => ExtensionTemplateManager(
          extensionManager: context.get<tool_extension.ToolExtensionManager>()!,
          fileSystem: memoryFileSystem,
        ),
      },
    );
  });
}

class MockExtensionTemplateManager extends Fake implements ExtensionTemplateManager {
  MockExtensionTemplateManager({required this.templates, required this.fileSystem});

  final List<core.ProjectTemplate> templates;
  final FileSystem fileSystem;
  List<core.ProjectTemplate>? _cached;

  @override
  List<core.ProjectTemplate> get cachedTemplates => _cached ?? const <core.ProjectTemplate>[];

  @override
  Future<List<core.ProjectTemplate>> getProjectTemplates() async {
    _cached = templates;
    return templates;
  }

  @override
  Directory resolveTemplateDirectory(String templatePath) {
    if (templatePath.startsWith('package:flutter_tools/')) {
      final String relativePart = templatePath.substring('package:flutter_tools/'.length);
      return fileSystem.directory(
        fileSystem.path.join('/', 'packages', 'flutter_tools', 'lib', relativePart),
      );
    }
    throw UnsupportedError('Unsupported template package path: $templatePath');
  }

  @override
  Future<Map<String, Object?>> generateTemplateParameters(
    String templateName,
    Map<String, Object?> toolParameters,
  ) async {
    return toolParameters;
  }
}

void _populatePubspecLock(MemoryFileSystem memoryFileSystem) {
  const FileSystem physicalFS = local_fs.LocalFileSystem();
  final String flutterRoot = Cache.flutterRoot!;
  final File physicalPubspecLock = physicalFS.file(
    physicalFS.path.join(flutterRoot, 'pubspec.lock'),
  );
  if (physicalPubspecLock.existsSync()) {
    final String content = physicalPubspecLock.readAsStringSync();
    memoryFileSystem.file(memoryFileSystem.path.join(flutterRoot, 'pubspec.lock'))
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  }
}
