// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/sdk/sdk_utils.dart';
import 'package:path/path.dart' as pathos;
import 'package:test/test.dart';

void main() {
  for (List<dynamic> osData in [
    ["C:\\windowspaths\\", "\\", pathos.windows],
    ["/posixpaths/", "/", pathos.posix],
  ]) {
    var prefix = osData[0] as String;
    var separator = osData[1] as String;
    var context = osData[2] as pathos.Context;
    var resourceProvider = MemoryResourceProvider(context: context);

    for (var libraryPath in getPaths(sdkPaths,
        addFilenames: false, prefix: prefix, separator: separator)) {
      for (var filePath in getPaths(inputPaths,
          addFilenames: true, prefix: prefix, separator: separator)) {
        File library = resourceProvider.getFile(libraryPath);
        File file = resourceProvider.getFile(filePath);
        test("sdk_util_test $libraryPath vs $filePath", () {
          String? relativePathIfInside =
              getRelativePathIfInside(library.path, file.path);
          expect(
              relativePathIfInside,
              getRelativePathIfInsideSlow(
                  resourceProvider.getFile(library.path), file, context));
          expect(
              relativePathIfInside,
              getRelativePathIfInsideSemi(
                  library.path, file.path, context.separator));
        });
      }
    }
  }
}

List<String> inputPaths = [
  "sky_engine/lib/async",
  "sky_engine/lib/collection",
  "sky_engine/lib/convert",
  "sky_engine/lib/core",
  "sky_engine/lib/developer",
  "sky_engine/lib/ffi",
  "sky_engine/lib/_http",
  "sky_engine/lib/_interceptors",
  "sky_engine/lib/internal",
  "sky_engine/lib/io",
  "sky_engine/lib/isolate",
  "sky_engine/lib/math",
  "sky_engine/lib/typed_data",
  "sky_engine/lib/ui",
  "flutter/lib",
  "project/test",
  "project/lib",
  ".pub-cache/hosted/pub.dev/foo/lib/src",
  ".pub-cache/hosted/pub.dev/foo/lib",
];

List<String> sdkPaths = [
  "sky_engine/lib/async/async.dart",
  "sky_engine/lib/collection/collection.dart",
  "sky_engine/lib/convert/convert.dart",
  "sky_engine/lib/core/core.dart",
  "sky_engine/lib/developer/developer.dart",
  "sky_engine/lib/ffi/ffi.dart",
  "sky_engine/lib/html/html_dart2js.dart",
  "sky_engine/lib/io/io.dart",
  "sky_engine/lib/isolate/isolate.dart",
  "sky_engine/lib/js/js.dart",
  "sky_engine/lib/js_util/js_util.dart",
  "sky_engine/lib/math/math.dart",
  "sky_engine/lib/typed_data/typed_data.dart",
  "sky_engine/lib/ui/ui.dart",
  "sky_engine/lib/wasm/wasm_types.dart",
  "sky_engine/lib/_http/http.dart",
  "sky_engine/lib/_interceptors/interceptors.dart",
  "sky_engine/lib/internal/internal.dart",
  "sky_engine/lib/_empty.dart",
];

Iterable<String> getPaths(List<String> input,
    {required bool addFilenames,
    required String prefix,
    required String separator}) sync* {
  for (String s in input) {
    String base = "$prefix${s.replaceAll("/", separator)}";
    if (addFilenames) {
      yield "$base${separator}a.dart";
      yield "$base${separator}ab.dart";
    } else {
      yield base;
    }
  }
}

String? getRelativePathIfInsideSemi(
    String libraryPath, String filePath, String separator) {
  String libDirPath =
      libraryPath.substring(0, libraryPath.lastIndexOf(separator) + 1);
  String fileDirPath =
      filePath.substring(0, filePath.lastIndexOf(separator) + 1);
  if (fileDirPath.startsWith(libDirPath)) {
    return filePath.substring(libDirPath.length);
  }
  return null;
}

String? getRelativePathIfInsideSlow(
    File libraryFile, File file, pathos.Context pathContext) {
  var libraryFolder = libraryFile.parent;
  if (libraryFolder.contains(file.path)) {
    return pathContext.relative(file.path, from: libraryFolder.path);
  }
  return null;
}
