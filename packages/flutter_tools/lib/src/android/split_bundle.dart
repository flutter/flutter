
import 'dart:io';
import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';

// The flutter build command and gen_snapshot should be run first to produce the expected files for this script.

String rootDir = path.join('..', '..', '..');
String splitDir = path.join('build', 'split');
String resDir = path.join(rootDir, 'android', 'app', 'src', 'main', 'res');
String androidManifestPath = path.join(rootDir, 'android', 'app', 'src', 'main', 'AndroidManifest.xml');
String bundleToolFileName = 'bundletool-all-1.0.0.jar';
String aapt2Path = path.join(rootDir, splitDir, 'tools', 'aapt2-4.2.0-alpha05-6645012-osx', 'aapt2');
String aapt2CompiledResOutput = path.join(rootDir, splitDir, 'compiled_resources');

String aapt2URL = 'https://dl.google.com/dl/android/maven2/com/android/tools/build/aapt2/';
String aapt2Version = '4.2.0-alpha06-6645012';
String platform = 'osx';

void main() async {
	rootDir = Directory(rootDir).absolute.path;

	// Download aapt2 tool
	String aapt2JarPath = '$splitDir/aapt2.jar';
	File aapt2Jar = File(aapt2JarPath);
	HttpClient().getUrl(Uri.parse('$aapt2URL$aapt2Version/aapt2-$aapt2Version-$platform.jar'))
    .then((HttpClientRequest request) => request.close())
    .then((HttpClientResponse response) => 
        response.pipe(aapt2Jar.openWrite()));

  // Decode the Zip file
  final archive = ZipDecoder().decodeBytes(aapt2Jar.readBytesSync());
  // Extract the contents of the Zip archive to disk.
  for (final file in archive) {
    final filename = file.name;
    if (file.isFile) {
      final data = file.content as List<int>;
      File('$splitDir/aapt2/' + filename)
        ..createSync(recursive: true)
        ..writeAsBytesSync(data);
    } else {
      Directory('out/' + filename)
        ..create(recursive: true);
    }
  }

  // aapt2 compile
	await Directory(aapt2CompiledResOutput).delete(recursive: true);
	await Directory(aapt2CompiledResOutput).create(recursive: true);
	Process.run(aapt2Path, [
		'compile',
		'--dir',
		resDir,
		'-o',
		aapt2CompiledResOutput,
	]).then((ProcessResult results) {
	  print(results.stdout);
	  print(results.stderr);
	})
	.catchError((e) {
	  print(e);
	});


	// compiled_resources.txt by adding filenames of .flat files.
	File flatFiles = new File(path.join(aapt2CompiledResOutput, 'compiled_resources.txt'));
	await flatFiles.create(recursive: true);
	IOSink sink = flatFiles.openWrite();
	for (int i = 0; i < filesInDir.length; i++) {
		FileSystemEntity entity = filesInDir[i];
		if (entity is File) {
			File file = entity;
			if (file.path.substring(file.path.length - 5) == '.flat') {
				sink.write('${file.path} ');
			}
		}
	}
	await sink.flush();
	sink.close();


	// aapt2 link --proto-format -o output.apk \
	// -I android_sdk/platforms/android_version/android.jar \
	// --manifest project_root/module_root/src/main/AndroidManifest.xml \
	// -R compiled_resources/*.flat \
	// --auto-add-overlay

	// aapt2 link
	await Directory(aapt2CompiledResOutput).create(recursive: true);
	Process.run(aapt2Path, [
		'link',
		// '-h',
		'--proto-format',
		'-o',
		path.join(aapt2CompiledResOutput, 'output.apk'),
		'--manifest',
		androidManifestPath,
		'-R',
		path.join(aapt2CompiledResOutput, 'compiled_resources.txt'),
		// '--auto-add-overlay',
		'-I',
		'/Users/garyq/Library/Android/sdk/platforms/android-28/android.jar'
	]).then((ProcessResult results) {
	  print(results.stdout);
	  print(results.stderr);
	})
	.catchError((e) {
	  print(e);
	});

	// extract resources.pb

	// gen_snapshot

	// Read gen_snapshot manifest
	File file = File(path.join('..', 'manifest.json'));
	String fileString = await file.readAsString();
	Map manifest = jsonDecode(fileString);
	ZipFileEncoder encoder = ZipFileEncoder();

	// Create bundletool zips
	List<Module> modules = List<Module>();
	for (Map loadingUnitMetadata in manifest['loadingUnits']) {
		Module module = Module(loadingUnitMetadata);

		await module.createDir();

		await module.setupFiles();

		await module.zip(encoder);

		modules.add(module);
	}

	// call bundle_tool to build aab
	String modulesArg = '--modules=';
	for (Module module in modules) {
		if (!module.isBase) {
			modulesArg += ',';
		}
		modulesArg += module.zipPath;
	}
	List<String> bundletoolArgs = [
		'-Xms300m', // Set minimum and maximum heap size to the same value
  	'-Xmx300m', // Set minimum and maximum heap size to the same value
  	'-jar',
  	path.join(rootDir, splitDir, 'tools', bundleToolFileName),
  	'build-bundle',
  	'--output',
  	path.join(rootDir, splitDir, 'appbundle.aab'),
  	modulesArg,
	];

	// Process.run('java', bundletoolArgs).then((ProcessResult results) {
	//   print(results.stdout);
	//   print(results.stderr);
	// })
	// .catchError((e) {
	//   print(e);
	// });
}

class Module {
	Module(Map metadata) {
		id = metadata['id'];
		isBase = id == 1;
		moduleName = isBase ? 'base' : id.toString();
		moduleSoPath = metadata['path'];
		modulePath = path.join(rootDir, splitDir, 'modules', moduleName);
		zipPath = path.join(rootDir, splitDir, 'modules', '$moduleName.zip');
	}

	int id;
	bool isBase;
	String moduleName;
	String moduleSoPath;
	String modulePath;
	String zipPath;

	void createDir() async {
		Directory moduleDir = Directory(path.join(modulePath));
		if (moduleDir.existsSync()) {
			await moduleDir.delete(recursive: true);
		}

		await Directory(path.join(modulePath, 'manifest')).create(recursive: true);
	  await Directory(path.join(modulePath, 'dex')).create(recursive: true);
	  await Directory(path.join(modulePath, 'res')).create(recursive: true);
		await Directory(path.join(modulePath, 'assets')).create(recursive: true);
	  await Directory(path.join(modulePath, 'root')).create(recursive: true);
	  await Directory(path.join(modulePath, 'lib')).create(recursive: true);
	}

	void setupFiles() async {
		await File(path.join(rootDir, moduleSoPath)).copy(path.join(modulePath, 'lib', 'libflutter.so'));

	  File androidManifest = new File(path.join(modulePath, 'manifest', 'AndroidManifest.xml'));
	  await androidManifest.create(recursive: true);
	  IOSink sink = androidManifest.openWrite();
// 	  sink.write(
// '''
// <manifest xmlns:dist="http://schemas.android.com/apk/distribution"
//     split="$moduleName"
//     android:isFeatureSplit="${isBase ? false : true}">

//     <dist:module dist:instant="false"
//     		dist:title="@string/module$id"
//     		<dist:fusing dist:include="true" />
// 		</dist:module>
// 		<dist:delivery>
// 				<dist:install-time>
// 						<dist:removable value="false" />
// 				</dist:install-time>
// 				<dist:on-demand/>
// 		</dist:delivery>
// 		<application android:hasCode="${isBase ? 'true' : 'false'}"${isBase ? ' tools:replace="android:hasCode"' : ''}>
// 		</application>
// </manifest>
// ''');

	  sink.write(
'''
<manifest xmlns:dist="http://schemas.android.com/apk/distribution"
    split="$moduleName"
    android:isFeatureSplit="${isBase ? false : true}">

    <dist:module dist:instant="false"
    		dist:title="@string/module$id"
    		<dist:fusing dist:include="true" />
		</dist:module>
		<dist:delivery>
				<dist:install-time>
						<dist:removable value="false" />
				</dist:install-time>
				<dist:on-demand/>
		</dist:delivery>
		<application android:hasCode="${isBase ? 'true' : 'false'}"${isBase ? ' tools:replace="android:hasCode"' : ''}>
		</application>
</manifest>
''');
	  sink.close();

	  File resources = new File(path.join(modulePath, 'resources.pb'));
	  await resources.create(recursive: true);
	  sink = resources.openWrite();
	  sink.write(
'''
''');
	  sink.close();
	}

	void zip(ZipFileEncoder encoder) async {
	  encoder.zipDirectory(Directory(modulePath), filename: zipPath);
	}
}
