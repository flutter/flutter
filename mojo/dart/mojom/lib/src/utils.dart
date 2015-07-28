// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of generate;

bool isMojomDart(String path) => path.endsWith('.mojom.dart');
bool isMojom(String path) => path.endsWith('.mojom');

/// An Error for problems on the command line.
class CommandLineError extends Error {
  final _msg;
  CommandLineError(this._msg);
  toString() => _msg;
}

/// An Error for failures of the bindings generation script.
class GenerationError extends Error {
  final _msg;
  GenerationError(this._msg);
  toString() => _msg;
}

/// An Error for failing to download a .mojom file.
class DownloadError extends Error {
  final _msg;
  DownloadError(this._msg);
  toString() => _msg;
}

/// The base type of data passed to actions for [mojomDirIter].
class PackageIterData {
  final Directory _mojomPackage;
  PackageIterData(this._mojomPackage);
  Directory get mojomPackage => _mojomPackage;
}

/// Data for [mojomDirIter] that includes the path to the Mojo SDK for bindings
/// generation.
class GenerateIterData extends PackageIterData {
  final Directory _mojoSdk;
  GenerateIterData(this._mojoSdk, Directory mojomPackage)
      : super(mojomPackage);
  Directory get mojoSdk => _mojoSdk;
}

/// The type of action performed by [mojomDirIter].
typedef Future MojomAction(PackageIterData data, Directory mojomDirectory);

packageDirIter(
    Directory packages, PackageIterData data, MojomAction action) async {
  await for (var package in packages.list()) {
    if (package is Directory) {
      await action(data, package);
    }
  }
}

/// Iterates over mojom directories of Dart packages, taking some action for
/// each.
///
/// For each 'mojom' subdirectory of each subdirectory in [packages], runs
/// [action] on the subdirectory passing along [data] to [action].
mojomDirIter(
    Directory packages, PackageIterData data, MojomAction action) async {
  await packageDirIter(packages, data, (d, p) async {
    if (p.path == d.mojomPackage.path) return;
    if (verbose) print("package = $p");
    final mojomDirectory = new Directory(path.join(p.path, 'mojom'));
    if (verbose) print("looking for = $mojomDirectory");
    if (await mojomDirectory.exists()) {
      await action(d, mojomDirectory);
    } else if (verbose) {
      print("$mojomDirectory not found");
    }
  });
}

/// Download file at [url] using [httpClient]. Throw a [DownloadError] if
/// the file is not successfully downloaded.
Future<String> getUrl(HttpClient httpClient, String url) async {
  try {
    var request = await httpClient.getUrl(Uri.parse(url));
    var response = await request.close();
    if (response.statusCode >= 400) {
      var msg = "Failed to download $url\nCode ${response.statusCode}";
      if (response.reasonPhrase != null) {
        msg = "$msg: ${response.reasonPhrase}";
      }
      throw new DownloadError(msg);
    }
    var fileString = new StringBuffer();
    await for (String contents in response.transform(UTF8.decoder)) {
      fileString.write(contents);
    }
    return fileString.toString();
  } catch(e) {
    throw new DownloadError("$e");
  }
}
