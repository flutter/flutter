// import 'dart:async';
// import 'dart:io' as io;
//
// import 'package:analyzer/file_system/physical_file_system.dart';
// import 'package:analyzer/src/context/packages.dart';
// import 'package:analyzer/src/dart/sdk/sdk.dart';
// import 'package:analyzer/src/generated/utilities_dart.dart';
// import 'package:analyzer/src/util/sdk.dart';
// import 'package:analyzer/src/workspace/blaze.dart';
// import 'package:analyzer/src/workspace/pub.dart';
// import 'package:analyzer/src/workspace/workspace.dart';
//
// void main() async {
//   final resourceProvider = PhysicalResourceProvider.INSTANCE;
//
//   final useGoogle3 = 1 == 1;
//   Workspace workspace;
//   String startPath;
//   if (!useGoogle3) {
//     final workspacePath =
//         '/Users/scheglov/Source/Dart/sdk.git/sdk/pkg/analyzer';
//     final packages = findPackagesFrom(
//       resourceProvider,
//       resourceProvider.getFolder(workspacePath),
//     );
//     workspace = PubWorkspace.find(
//       resourceProvider,
//       packages,
//       workspacePath,
//     )!;
//     const pkgPath = '/Users/scheglov/Source/Dart/sdk.git/sdk/pkg';
//     startPath = '$pkgPath/analyzer/example/ddd05.dart';
//   } else {
//     const workspacePath = '/google/src/cloud/scheglov/my-20230122/google3';
//     workspace = BlazeWorkspace.forBuild(
//       root: resourceProvider.getFolder(workspacePath),
//     );
//     const startPackagePath = '$workspacePath/nbu/paisa/gpay/app';
//     startPath = '$startPackagePath/lib/src/programmatic_main.dart';
//   }
//
//   final sdkPath = getSdkPath();
//   final sourceFactory = workspace.createSourceFactory(
//     FolderBasedDartSdk(
//       resourceProvider,
//       resourceProvider.getFolder(sdkPath),
//     ),
//     null,
//   );
//
//   final readPathSet = <String>{};
//
//   final toReadPathSet = <String>{};
//   final toReadPathSetController = StreamController<void>();
//
//   final importRegExp = RegExp(r'''import\s+'(.+)'(\s+as\s+\w+)?\s*;''');
//   final exportRegExp = RegExp(r'''export\s+'(.+)'\s*;''');
//   final partRegExp = RegExp(r'''part\s+'(.+)'\s*;''');
//
//   void readOne(String path, Uri uri) {
//     if (readPathSet.add(path)) {
//       print(path);
//       toReadPathSet.add(path);
//       io.File(path).readAsString().then(
//         (content) {
//           final allMatches = [
//             ...importRegExp.allMatches(content),
//             ...exportRegExp.allMatches(content),
//             ...partRegExp.allMatches(content),
//           ];
//           for (final match in allMatches) {
//             final uriStr = match.group(1)!;
//             print('  ${match.group(0)}');
//             print('  uriStr: $uriStr');
//             final uri2 = Uri.parse(uriStr);
//             final uri3 = resolveRelativeUri(uri, uri2);
//             print('    uri3: $uri3');
//             final source = sourceFactory.forUri2(uri3);
//             print('    source: $source');
//             if (source != null) {
//               readOne(source.fullName, uri3);
//             } else {
//               print('    !!!! no Source');
//             }
//           }
//         },
//         onError: (exception, stackTrace) {},
//       ).whenComplete(() {
//         toReadPathSet.remove(path);
//         toReadPathSetController.sink.add(null);
//       });
//     }
//   }
//
//   void readOne2(String path, Uri uri, {int level = 0}) {
//     if (readPathSet.add(path)) {
//       print(path);
//       toReadPathSet.add(path);
//       String? content;
//       try {
//         content = io.File(path).readAsStringSync();
//       } catch (_) {
//         print('  !!!! cannot read');
//       }
//       //print(content);
//       if (content != null) {
//         final allMatches = [
//           ...importRegExp.allMatches(content),
//           ...exportRegExp.allMatches(content),
//           ...partRegExp.allMatches(content),
//         ];
//
//         for (final match in allMatches) {
//           final uriStr = match.group(1)!;
//           print('  ${match.group(0)}');
//           print('  uriStr: $uriStr');
//           final uri2 = Uri.parse(uriStr);
//           final uri3 = resolveRelativeUri(uri, uri2);
//           print('    uri3: $uri3');
//           final source = sourceFactory.forUri2(uri3);
//           print('    source: $source');
//           if (source != null) {
//             readOne2(source.fullName, uri3, level: level + 1);
//           } else {
//             print('    !!!! no Source');
//           }
//         }
//       }
//       toReadPathSet.remove(path);
//       if (level == 0) {
//         toReadPathSetController.sink.add(null);
//       }
//     }
//   }
//
//   final startUri = sourceFactory.pathToUri(startPath)!;
//   print('startPath: $startPath');
//   print('startUri: $startUri');
//
//   final timer = Stopwatch()..start();
//   readOne(startPath, startUri);
//
//   toReadPathSetController.stream.listen((_) {
//     if (toReadPathSet.isEmpty) {
//       timer.stop();
//       print('Time: ${timer.elapsedMilliseconds}');
//       print('Files: ${readPathSet.length}');
//     }
//   });
// }
