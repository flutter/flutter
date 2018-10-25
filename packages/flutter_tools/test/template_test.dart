import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/template.dart';
import 'package:test/test.dart';

void main() {
  group('End-to-End templating tests', () {
    Directory tempDir;
    Directory templateDir;
    Directory destinationDir;
    const String fileContent = 'This is the content of the file.';

    setUpAll(() {
      Cache.disableLocking();
    });

    setUp(() {
      tempDir = fs.systemTempDirectory.createTempSync('flutter_tools_template_test.');
      templateDir = tempDir.childDirectory('fake_template')..createSync(recursive: true);
      destinationDir = tempDir.childDirectory('fake_destination')..createSync(recursive: true);
    });

    tearDown(() {
      _tryToDelete(tempDir);
    });

    test('Template directly copies files with .copy.tmpl extension', () async {
      // Prepare a file structure that represents a template.
      await _createFileStructure(templateDir, <String>[
        'my_dir.tmpl/copyfile.copy.tmpl',
      ]);
      await _writeFileContent(templateDir, 'my_dir.tmpl/copyfile.copy.tmpl', fileContent);

      final Template template = Template();
      await template.render(
        templateDir,
        destinationDir,
        <String, dynamic>{},
        overwriteExisting: false,
        printStatusWhenWriting: false,
      );

      // Verify that a copied file exists, and that it's content matches the original.
      await _expectedFiles(destinationDir, <String>[
        'my_dir/copyfile',
      ]);
      await _expectedContent(destinationDir, 'my_dir/copyfile', fileContent);
    });

    test('Template directly copies files without template extension when those files are within a directory with a .tmpl extension', () async {
      // Prepare a file structure that represents a template.
      await _createFileStructure(templateDir, <String>[
        'my_dir.tmpl/copyfile',
      ]);
      await _writeFileContent(templateDir, 'my_dir.tmpl/copyfile', fileContent);

      final Template template = Template();
      await template.render(
        templateDir,
        destinationDir,
        <String, dynamic>{},
        overwriteExisting: false,
        printStatusWhenWriting: false,
      );

      // Verify that a copied file exists, and that it's content matches the original.
      await _expectedFiles(destinationDir, <String>[
        'my_dir/copyfile',
      ]);
      await _expectedContent(destinationDir, 'my_dir/copyfile', fileContent);
    });

    test('Template ignores files without template extension when those files are within a directory without a .tmpl extension', () async {
      // Prepare a file structure that represents a template.
      await _createFileStructure(templateDir, <String>[
        'dir_with_template_files/regularfile',
        'dir_with_template_files/copyfile.copy.tmpl',
      ]);

      final Template template = Template();
      await template.render(
        templateDir,
        destinationDir,
        <String, dynamic>{},
        overwriteExisting: false,
        printStatusWhenWriting: false,
      );

      // Verify the the directory was copied along with its template file, but
      // its no-extension file was not copied.
      await _expectedFiles(destinationDir, <String>[
        'dir_with_template_files/copyfile',
      ]);
      await _unexpectedFiles(destinationDir, <String>[
        'dir_with_template_files/regularfile',
      ]);
    });

    test('Template ignores directories that do not contain .tmpl files', () async {
      // Prepare a file structure that represents a template.
      await _createFileStructure(templateDir, <String>[
        'dir_with_no_templates/regularfile',
      ]);

      final Template template = Template();
      await template.render(
        templateDir,
        destinationDir,
        <String, dynamic>{},
        overwriteExisting: false,
        printStatusWhenWriting: false,
      );

      // Verify the directory was not copied.
      await _unexpectedFiles(destinationDir, <String>[
        'dir_with_no_templates/',
      ]);
    });

    test('Template selects java directories and excludes kotlin directories for a java project', () async {
      // Prepare a file structure that represents a template.
      await _createFileStructure(templateDir, <String>[
        'my_dir-java.tmpl/MyJavaFile.java',
        'my_dir-kotlin.tmpl/MyKotlinFile.kt',
      ]);

      final Template template = Template();
      await template.render(
        templateDir,
        destinationDir,
        <String, dynamic>{
          'androidLanguage': 'java',
        },
        overwriteExisting: false,
        printStatusWhenWriting: false,
      );

      // Verify that my_dir exists, and it contains the java file.
      await _expectedFiles(destinationDir, <String>[
        'my_dir/MyJavaFile.java',
      ]);

      // Ensure that the kotlin file wasn't copied.
      await _unexpectedFiles(destinationDir, <String>[
        'my_dir/MyKotlinFile.kt',
      ]);
    });

    test('Template selects kotlin directories and excludes java directories for a kotlin project', () async {
      // Prepare a file structure that represents a template.
      await _createFileStructure(templateDir, <String>[
        'my_dir-java.tmpl/MyJavaFile.java',
        'my_dir-kotlin.tmpl/MyKotlinFile.kt',
      ]);

      final Template template = Template();
      await template.render(
        templateDir,
        destinationDir,
        <String, dynamic>{
          'androidLanguage': 'kotlin',
        },
        overwriteExisting: false,
        printStatusWhenWriting: false,
      );

      // Verify that my_dir exists, and it contains the kotlin file.
      await _expectedFiles(destinationDir, <String>[
        'my_dir/MyKotlinFile.kt',
      ]);

      // Ensure that the java file wasn't copied.
      await _unexpectedFiles(destinationDir, <String>[
        'my_dir/MyJavaFile.java',
      ]);
    });

    test('Template selects obj-c directories and excludes swift directories for an obj-c project', () async {
      // Prepare a file structure that represents a template.
      await _createFileStructure(templateDir, <String>[
        'my_dir-swift.tmpl/MySwiftFile.swift',
        'my_dir-objc.tmpl/MyObjCFile.h',
        'my_dir-objc.tmpl/MyObjCFile.m',
      ]);

      final Template template = Template();
      await template.render(
        templateDir,
        destinationDir,
        <String, dynamic>{
          'iosLanguage': 'objc',
        },
        overwriteExisting: false,
        printStatusWhenWriting: false,
      );

      // Verify that my_dir exists, and it contains the obj-c files.
      await _expectedFiles(destinationDir, <String>[
        'my_dir/MyObjCFile.h',
        'my_dir/MyObjCFile.m',
      ]);

      // Ensure that the swift files weren't copied.
      await _unexpectedFiles(destinationDir, <String>[
        'my_dir/MySwiftFile.swift',
      ]);
    });

    test('Template selects swift directories and excludes obj-c directories for a swift project', () async {
      // Prepare a file structure that represents a template.
      await _createFileStructure(templateDir, <String>[
        'my_dir-swift.tmpl/MySwiftFile.swift',
        'my_dir-objc.tmpl/MyObjCFile.h',
        'my_dir-objc.tmpl/MyObjCFile.m',
      ]);

      final Template template = Template();
      await template.render(
        templateDir,
        destinationDir,
        <String, dynamic>{
          'iosLanguage': 'swift',
        },
        overwriteExisting: false,
        printStatusWhenWriting: false,
      );

      // Verify that my_dir exists, and it contains the swift files.
      await _expectedFiles(destinationDir, <String>[
        'my_dir/MySwiftFile.swift',
      ]);

      // Ensure that the obj-c files weren't copied.
      await _unexpectedFiles(destinationDir, <String>[
        'my_dir/MyObjCFile.h',
        'my_dir/MyObjCFile.m',
      ]);
    });
  });

  group('TemplatePathMapper integration tests', () {
    test('it applies all rules to a given file list of paths', () async {
      final Map<String, dynamic> context = <String, dynamic>{
        'androidLanguage': 'java',
        'iosLanguage': 'objc',
        'androidIdentifier': 'io.flutter.myproject',
        'projectName': 'my_project',
        'pluginClass': 'MyPlugin',
      };

      final TemplateInstructions actualInstructions = initialInstructions()
        .sources(<String>[
          'template_dir/file_to_mustache.tmpl',
          'template_dir/file_to_copy.copy.tmpl',
          'template_dir/dir1.tmpl/file_to_copy',
          'template_dir/android-java.tmpl/androidIdentifier/src/MyClass.java',
          'template_dir/android-kotlin.tmpl/androidIdentifier/src/MyFile.kt',
          'template_dir/ios-objc.tmpl/src/MyFile.h',
          'template_dir/ios-objc.tmpl/src/MyFile.m',
          'template_dir/ios-swift.tmpl/src/MyFile.swift',
          'template_dir/plugin.tmpl/src/pluginClass.java'
        ]).build();

      final TemplateInstructions expectedInstructions = expectInstructions()
        .mustache(from: 'template_dir/file_to_mustache.tmpl', to: 'template_dir/file_to_mustache')
        .copy(from: 'template_dir/file_to_copy.copy.tmpl', to: 'template_dir/file_to_copy')
        .copy(from: 'template_dir/dir1.tmpl/file_to_copy', to: 'template_dir/dir1/file_to_copy')
        .copy(from: 'template_dir/android-java.tmpl/androidIdentifier/src/MyClass.java', to: 'template_dir/android/io/flutter/myproject/src/MyClass.java')
        .copy(from: 'template_dir/ios-objc.tmpl/src/MyFile.h', to: 'template_dir/ios/src/MyFile.h')
        .copy(from: 'template_dir/ios-objc.tmpl/src/MyFile.m', to: 'template_dir/ios/src/MyFile.m')
        .copy(from: 'template_dir/plugin.tmpl/src/pluginClass.java', to: 'template_dir/plugin/src/MyPlugin.java')
        .build();

      TemplateRules().applyTo(context, actualInstructions, '.tmpl', '.copy.tmpl');

      expect(actualInstructions, expectedInstructions);
    });

    test('it excludes flutter_root paths when context does not have \"withRootModule\" set.', () async {
      final Map<String, dynamic> context = <String, dynamic>{};

      final TemplateInstructions actualInstructions = initialInstructions()
          .sources(<String>[
            'template_dir/flutter_root/file_to_copy.copy.tmpl',
          ]).build();

      final TemplateInstructions expectedTemplateInstructions = expectInstructions().build();

      TemplateRules().applyTo(context, actualInstructions, '.tmpl', '.copy.tmpl');

      expect(actualInstructions, expectedTemplateInstructions);
    });

    test('it includes flutter_root paths when context has \"withRootModule\" set to true.', () async {
      final Map<String, dynamic> context = <String, dynamic>{
        'withRootModule': true,
      };

      final TemplateInstructions actualInstructions = initialInstructions()
          .sources(<String>[
            'template_dir/flutter_root/file_to_copy.copy.tmpl',
          ]).build();

      final TemplateInstructions expectedTemplateInstructions = expectInstructions()
          .copy(from: 'template_dir/flutter_root/file_to_copy.copy.tmpl', to: 'template_dir/flutter_root/file_to_copy')
          .build();

      TemplateRules().applyTo(context, actualInstructions, '.tmpl', '.copy.tmpl');

      expect(actualInstructions, expectedTemplateInstructions);
    });
  });

  group('FlutterRootFilterRule unit tests', () {
    test('it excludes flutter_root paths when context does not have \"withRootModule\" set.', () async {
      final Map<String, dynamic> context = <String, dynamic>{};

      final TemplateInstructions actualInstructions = initialInstructions()
          .sources(<String>[
            'template_dir/flutter_root/file_to_copy.copy.tmpl',
          ]).build();

      final TemplateInstructions expectedTemplateInstructions = expectInstructions().build();

      TemplateRules().applyTo(context, actualInstructions, '.tmpl', '.copy.tmpl');

      expect(actualInstructions, expectedTemplateInstructions);
    });

    test('it includes flutter_root paths when \"withRootModule\" is true.', () async {
      final TemplateInstructions actualInstructions = initialInstructions()
          .sources(<String>[
            'template_dir/flutter_root/file_to_copy.copy.tmpl',
          ]).build();

      final TemplateInstructions expectedTemplateInstructions = expectInstructions()
          .copy(from: 'template_dir/flutter_root/file_to_copy.copy.tmpl', to: 'template_dir/flutter_root/file_to_copy.copy.tmpl')
          .build();

      FlutterRootFilterRule(withRootModule: true).applyTo(actualInstructions);

      expect(actualInstructions, expectedTemplateInstructions);
    });
  });

  group('LanguageFilterRule unit tests', () {
    test('it filters out kotlin paths when java is selected', () async {
      final TemplateInstructions actualInstructions = initialInstructions()
          .sources(<String>[
            'template_dir/my_dir-java.tmpl/SomeClass.java',
            'template_dir/my_dir-kotlin.tmpl/SomeFile.kt',
          ]).build();

      final TemplateInstructions expectedTemplateInstructions = expectInstructions()
          .copy(from: 'template_dir/my_dir-java.tmpl/SomeClass.java', to: 'template_dir/my_dir/SomeClass.java')
          .build();

      LanguageFilterRule(androidLanguage: 'java').applyTo(actualInstructions);

      expect(actualInstructions, expectedTemplateInstructions);
    });

    test('it filters out java paths when kotlin is selected', () async {
      final TemplateInstructions actualInstructions = initialInstructions()
          .sources(<String>[
            'template_dir/my_dir-java.tmpl/SomeClass.java',
            'template_dir/my_dir-kotlin.tmpl/SomeFile.kt',
          ]).build();

      final TemplateInstructions expectedTemplateInstructions = expectInstructions()
          .copy(from: 'template_dir/my_dir-kotlin.tmpl/SomeFile.kt', to: 'template_dir/my_dir/SomeFile.kt')
          .build();

      LanguageFilterRule(androidLanguage: 'kotlin').applyTo(actualInstructions);

      expect(actualInstructions, expectedTemplateInstructions);
    });

    test('it filters out swift paths when obj-c is selected', () async {
      final TemplateInstructions actualInstructions = initialInstructions()
          .sources(<String>[
            'template_dir/my_dir-objc.tmpl/SomeFile.h',
            'template_dir/my_dir-objc.tmpl/SomeFile.m',
            'template_dir/my_dir-swift.tmpl/SomeFile.swift',
          ]).build();

      final TemplateInstructions expectedTemplateInstructions = expectInstructions()
          .copy(from: 'template_dir/my_dir-objc.tmpl/SomeFile.h', to: 'template_dir/my_dir/SomeFile.h')
          .copy(from: 'template_dir/my_dir-objc.tmpl/SomeFile.m', to: 'template_dir/my_dir/SomeFile.m')
          .build();

      LanguageFilterRule(iosLanguage: 'objc').applyTo(actualInstructions);

      expect(actualInstructions, expectedTemplateInstructions);
    });

    test('it filters out obj-c paths when swift is selected', () async {
      final TemplateInstructions actualInstructions = initialInstructions()
          .sources(<String>[
            'template_dir/my_dir-objc.tmpl/SomeFile.h',
            'template_dir/my_dir-objc.tmpl/SomeFile.m',
            'template_dir/my_dir-swift.tmpl/SomeFile.swift',
          ]).build();

      final TemplateInstructions expectedTemplateInstructions = expectInstructions()
          .copy(from: 'template_dir/my_dir-swift.tmpl/SomeFile.swift', to: 'template_dir/my_dir/SomeFile.swift')
          .build();

      LanguageFilterRule(iosLanguage: 'swift').applyTo(actualInstructions);

      expect(actualInstructions, expectedTemplateInstructions);
    });

    test('it does not filter out language-agnostic paths', () async {
      final TemplateInstructions actualInstructions = initialInstructions()
          .sources(<String>[
            'template_dir/my_dir/some_file',
          ]).build();

      final TemplateInstructions expectedTemplateInstructions = expectInstructions()
          .copy(from: 'template_dir/my_dir/some_file', to: 'template_dir/my_dir/some_file')
          .build();

      LanguageFilterRule(
        androidLanguage: 'java',
        iosLanguage: 'objc',
      ).applyTo(actualInstructions);

      expect(actualInstructions, expectedTemplateInstructions);
    });
  });

  group('FileCopyAndExpansionRule unit tests', () {
    test('it marks mustache files, and strips .tmpl and .copy.tmpl from paths', () async {
      final TemplateInstructions actualInstructions = initialInstructions()
          .sources(<String>[
            'template_dir/my_dir.tmpl/template_file.tmpl',
            'template_dir/my_dir.tmpl/copy_file_with_ext.copy.tmpl',
            'template_dir/my_dir.tmpl/copy_file',
          ]).build();

      final TemplateInstructions expectedTemplateInstructions = expectInstructions()
          .mustache(from: 'template_dir/my_dir.tmpl/template_file.tmpl', to: 'template_dir/my_dir/template_file')
          .copy(from: 'template_dir/my_dir.tmpl/copy_file_with_ext.copy.tmpl', to: 'template_dir/my_dir/copy_file_with_ext')
          .copy(from: 'template_dir/my_dir.tmpl/copy_file', to: 'template_dir/my_dir/copy_file')
          .build();

      FileCopyAndExpansionRule(
        templateExtension: '.tmpl',
        copyTemplateExtension: '.copy.tmpl',
      ).applyTo(actualInstructions);

      expect(actualInstructions, expectedTemplateInstructions);
    });
  });

  group('AndroidIdentifierNameReplacementRule unit tests', () {
    test('it expands \"androidIdentifier\" into a new path', () async {
      final TemplateInstructions actualInstructions = initialInstructions()
          .sources(<String>[
            'template_dir/my_dir/androidIdentifier/some_other_dir',
          ]).build();

      final TemplateInstructions expectedTemplateInstructions = expectInstructions()
          .copy(
            from: 'template_dir/my_dir/androidIdentifier/some_other_dir',
            to: 'template_dir/my_dir/io/flutter/myapp/some_other_dir',
          )
          .build();

      AndroidIdentifierNameReplacementRule(
        androidIdentifier: 'io.flutter.myapp',
        pathSeparator: '/',
      ).applyTo(actualInstructions);

      expect(actualInstructions, expectedTemplateInstructions);
    });

    test('it does nothing when no \"androidIdentifier\" exists in path', () async {
      final TemplateInstructions actualInstructions = initialInstructions()
          .sources(<String>[
            'template_dir/my_dir/some_other_dir',
          ]).build();

      final TemplateInstructions expectedTemplateInstructions = expectInstructions()
          .copy(from: 'template_dir/my_dir/some_other_dir', to: 'template_dir/my_dir/some_other_dir')
          .build();

      AndroidIdentifierNameReplacementRule(
        androidIdentifier: 'io.flutter.myapp',
        pathSeparator: '/',
      ).applyTo(actualInstructions);

      expect(actualInstructions, expectedTemplateInstructions);
    });

    test('it does nothing when \"androidIdentifier\" is in path but no identifier expansion is provided', () async {
      final TemplateInstructions actualInstructions = initialInstructions()
          .sources(<String>[
            'template_dir/my_dir/androidIdentifier/some_other_dir',
          ]).build();

      final TemplateInstructions expectedTemplateInstructions = expectInstructions()
          .copy(from: 'template_dir/my_dir/androidIdentifier/some_other_dir', to: 'template_dir/my_dir/androidIdentifier/some_other_dir')
          .build();

      AndroidIdentifierNameReplacementRule(
        androidIdentifier: null,
        pathSeparator: '/',
      ).applyTo(actualInstructions);

      expect(actualInstructions, expectedTemplateInstructions);
    });
  });

  group('ProjectNameReplacementRule unit tests', () {
    test('it replaces \"projectName\" with the project name', () async {
      final TemplateInstructions actualInstructions = initialInstructions()
          .sources(<String>[
            'template_dir/my_dir/projectName/some_other_dir',
          ]).build();

      final TemplateInstructions expectedTemplateInstructions = expectInstructions()
          .copy(from: 'template_dir/my_dir/projectName/some_other_dir', to: 'template_dir/my_dir/myProject/some_other_dir')
          .build();

      ProjectNameReplacementRule(
        projectName: 'myProject',
      ).applyTo(actualInstructions);

      expect(actualInstructions, expectedTemplateInstructions);
    });

    test('it does nothing when no \"projectName\" exists in path', () async {
      final TemplateInstructions actualInstructions = initialInstructions()
          .sources(<String>[
            'template_dir/my_dir/some_other_dir',
          ]).build();

      final TemplateInstructions expectedTemplateInstructions = expectInstructions()
          .copy(from: 'template_dir/my_dir/some_other_dir', to: 'template_dir/my_dir/some_other_dir')
          .build();

      ProjectNameReplacementRule(
        projectName: 'myProject',
      ).applyTo(actualInstructions);

      expect(actualInstructions, expectedTemplateInstructions);
    });

    test('it does nothing when \"projectName\" is in path but no project name replacement is provided', () async {
      final TemplateInstructions actualInstructions = initialInstructions()
          .sources(<String>[
            'template_dir/my_dir/projectName/some_other_dir',
          ]).build();

      final TemplateInstructions expectedTemplateInstructions = expectInstructions()
          .copy(from: 'template_dir/my_dir/projectName/some_other_dir', to: 'template_dir/my_dir/projectName/some_other_dir')
          .build();

      ProjectNameReplacementRule(
        projectName: null,
      ).applyTo(actualInstructions);

      expect(actualInstructions, expectedTemplateInstructions);
    });
  });

  group('PluginNameReplacement unit tests', () {
    test('it replaces \"pluginClass\" with the plugin class name', () async {
      final TemplateInstructions actualInstructions = initialInstructions()
          .sources(<String>[
            'template_dir/my_dir/pluginClass/some_other_dir',
          ]).build();

      final TemplateInstructions expectedTemplateInstructions = expectInstructions()
          .copy(from: 'template_dir/my_dir/pluginClass/some_other_dir', to: 'template_dir/my_dir/myPlugin/some_other_dir')
          .build();

      PluginNameReplacementRule(
        pluginClassName: 'myPlugin',
      ).applyTo(actualInstructions);

      expect(actualInstructions, expectedTemplateInstructions);
    });

    test('it does nothing when no \"pluginClass\" exists in path', () async {
      final TemplateInstructions actualInstructions = initialInstructions()
          .sources(<String>[
            'template_dir/my_dir/some_other_dir',
          ]).build();

      final TemplateInstructions expectedTemplateInstructions = expectInstructions()
          .copy(from: 'template_dir/my_dir/some_other_dir', to: 'template_dir/my_dir/some_other_dir')
          .build();

      PluginNameReplacementRule(
        pluginClassName: 'myPlugin',
      ).applyTo(actualInstructions);

      expect(actualInstructions, expectedTemplateInstructions);
    });

    test('it does nothing when \"pluginClass\" is in path but no plugin class name is provided', () async {
      final TemplateInstructions actualInstructions = initialInstructions()
          .sources(<String>[
            'template_dir/my_dir/pluginClass/some_other_dir',
          ]).build();

      final TemplateInstructions expectedTemplateInstructions = expectInstructions()
          .copy(from: 'template_dir/my_dir/pluginClass/some_other_dir', to: 'template_dir/my_dir/pluginClass/some_other_dir')
          .build();

      PluginNameReplacementRule(
        pluginClassName: null,
      ).applyTo(actualInstructions);

      expect(actualInstructions, expectedTemplateInstructions);
    });
  });
}

Future<void> _createFileStructure(Directory baseDir, List<String> paths) async {
  for (int i = 0; i < paths.length; i += 1) {
    final String fullPath = fs.path.absolute(baseDir.absolute.path, paths[i]);
    if (fullPath.endsWith('/')) {
      // This path represents a directory.
      fs.directory(fullPath).createSync(recursive: true);
    } else {
      // This path represents a file.
      fs.file(fullPath).createSync(recursive: true);
    }
  }
}

Future<void> _expectedFiles(Directory baseDir, List<String> paths) async {
  for (int i = 0; i < paths.length; i += 1) {
    final String fullPath = fs.path.absolute(baseDir.absolute.path, paths[i]);
    if (fullPath.endsWith('/')) {
      // This path represents a directory.
      expect(fs.directory(fullPath).existsSync(), true);
    } else {
      // This path represents a file.
      expect(fs.file(fullPath).existsSync(), true);
    }
  }
}

Future<void> _unexpectedFiles(Directory baseDir, List<String> paths) async {
  for (int i = 0; i < paths.length; i += 1) {
    final String fullPath = fs.path.absolute(baseDir.absolute.path, paths[i]);
    if (fullPath.endsWith('/')) {
      // This path represents a directory.
      expect(fs.directory(fullPath).existsSync(), false);
    } else {
      // This path represents a file.
      expect(fs.file(fullPath).existsSync(), false);
    }
  }
}

Future<File> _writeFileContent(Directory baseDir, String filePath, String content) async {
  final String fullPath = fs.path.absolute(baseDir.absolute.path, filePath);
  final File file = fs.file(fullPath);
  file.createSync(recursive: true);
  final IOSink output = file.openWrite()..write(content);
  await output.flush();
  await output.close();

  return file;
}

Future<void> _expectedContent(Directory baseDir, String path, String content) async {
  final String fullPath = fs.path.absolute(baseDir.absolute.path, path);
  final String fileContent = await fs.file(fullPath).readAsString(encoding: ascii);
  expect(fileContent, content);
}

void _tryToDelete(Directory directory) {
  // This should not be necessary, but it turns out that
  // on Windows it's common for deletions to fail due to
  // bogus (we think) "access denied" errors.
  try {
    directory.deleteSync(recursive: true);
  } on FileSystemException catch (error) {
    print('Failed to delete ${directory.path}: $error');
  }
}