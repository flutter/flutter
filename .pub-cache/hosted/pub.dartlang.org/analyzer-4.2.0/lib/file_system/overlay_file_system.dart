// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/source_resource.dart';
import 'package:path/path.dart' as pathos;
import 'package:watcher/watcher.dart';

/// A resource provider that allows clients to overlay the file system provided
/// by a base resource provider. These overlays allow both the contents and
/// modification stamps of files to be different than what the base resource
/// provider would report.
///
/// This provider does not report watch events when overlays are added, modified
/// or removed.
class OverlayResourceProvider implements ResourceProvider {
  /// The underlying resource provider used to access files and folders that
  /// do not have an overlay.
  final ResourceProvider baseProvider;

  /// A map from the paths of files for to the overlay data.
  final Map<String, _OverlayFileData> _overlays = {};

  /// Initialize a newly created resource provider to represent an overlay on
  /// the given [baseProvider].
  OverlayResourceProvider(this.baseProvider);

  @override
  pathos.Context get pathContext => baseProvider.pathContext;

  @override
  File getFile(String path) => _OverlayFile(this, baseProvider.getFile(path));

  @override
  Folder getFolder(String path) =>
      _OverlayFolder(this, baseProvider.getFolder(path));

  @override
  Resource getResource(String path) {
    if (hasOverlay(path)) {
      return _OverlayResource._from(this, baseProvider.getFile(path));
    } else if (_hasOverlayIn(path)) {
      return _OverlayResource._from(this, baseProvider.getFolder(path));
    }
    return _OverlayResource._from(this, baseProvider.getResource(path));
  }

  @override
  Folder? getStateLocation(String pluginId) {
    var location = baseProvider.getStateLocation(pluginId);
    return location != null ? _OverlayFolder(this, location) : null;
  }

  /// Return `true` if there is an overlay associated with the file at the given
  /// [path].
  bool hasOverlay(String path) => _overlays.containsKey(path);

  /// Remove any overlay of the file at the given [path]. The state of the file
  /// in the base resource provider will not be affected.
  bool removeOverlay(String path) {
    return _overlays.remove(path) != null;
  }

  /// Overlay the content of the file at the given [path]. The file will appear
  /// to have the given [content] and [modificationStamp] even if the file is
  /// modified in the base resource provider.
  void setOverlay(String path,
      {required String content, required int modificationStamp}) {
    _overlays[path] = _OverlayFileData(content, modificationStamp);
  }

  /// Copy any overlay for the file at the [oldPath] to be an overlay for the
  /// file with the [newPath].
  void _copyOverlay(String oldPath, String newPath) {
    var data = _overlays[oldPath];
    if (data != null) {
      _overlays[newPath] = data;
    }
  }

  /// Return the content of the overlay of the file at the given [path], or
  /// `null` if there is no overlay for the specified file.
  String? _getOverlayContent(String path) {
    return _overlays[path]?.content;
  }

  /// Return the modification stamp of the overlay of the file at the given
  /// [path], or `null` if there is no overlay for the specified file.
  int? _getOverlayModificationStamp(String path) {
    return _overlays[path]?.modificationStamp;
  }

  /// Return `true` if there is an overlay associated with at least one file
  /// contained inside the folder with the given [folderPath].
  bool _hasOverlayIn(String folderPath) => _overlays.keys
      .any((filePath) => pathContext.isWithin(folderPath, filePath));

  /// Move any overlay for the file at the [oldPath] to be an overlay for the
  /// file with the [newPath].
  void _moveOverlay(String oldPath, String newPath) {
    var data = _overlays.remove(oldPath);
    if (data != null) {
      _overlays[newPath] = data;
    }
  }

  /// Return the paths of all of the overlaid files that are children of the
  /// given [folder], either directly or indirectly.
  Iterable<String> _overlaysInFolder(String folderPath) => _overlays.keys
      .where((filePath) => pathContext.isWithin(folderPath, filePath));
}

/// A file from an [OverlayResourceProvider].
class _OverlayFile extends _OverlayResource implements File {
  /// Initialize a newly created file to have the given [provider] and to
  /// correspond to the given [file] from the provider's base resource provider.
  _OverlayFile(super.provider, File super.file);

  @Deprecated('Use watch() instead')
  @override
  Stream<WatchEvent> get changes => watch().changes;

  @override
  bool get exists => provider.hasOverlay(path) || _resource.exists;

  @override
  int get lengthSync {
    String? content = provider._getOverlayContent(path);
    if (content != null) {
      return content.length;
    }
    return _file.lengthSync;
  }

  @override
  int get modificationStamp {
    int? stamp = provider._getOverlayModificationStamp(path);
    if (stamp != null) {
      return stamp;
    }
    return _file.modificationStamp;
  }

  /// Return the file from the base resource provider that corresponds to this
  /// folder.
  File get _file => _resource as File;

  @override
  File copyTo(Folder parentFolder) {
    String newPath = provider.pathContext.join(parentFolder.path, shortName);
    provider._copyOverlay(path, newPath);
    if (_file.exists) {
      if (parentFolder is _OverlayFolder) {
        return _OverlayFile(provider, _file.copyTo(parentFolder._folder));
      }
      return _OverlayFile(provider, _file.copyTo(parentFolder));
    } else {
      return _OverlayFile(provider, provider.baseProvider.getFile(newPath));
    }
  }

  @override
  Source createSource([Uri? uri]) =>
      FileSource(this, uri ?? provider.pathContext.toUri(path));

  @override
  void delete() {
    bool hadOverlay = provider.removeOverlay(path);
    if (_resource.exists) {
      _resource.delete();
    } else if (!hadOverlay) {
      throw FileSystemException(path, 'does not exist');
    }
  }

  @override
  Uint8List readAsBytesSync() {
    String? content = provider._getOverlayContent(path);
    if (content != null) {
      return utf8.encode(content) as Uint8List;
    }
    return _file.readAsBytesSync();
  }

  @override
  String readAsStringSync() {
    String? content = provider._getOverlayContent(path);
    if (content != null) {
      return content;
    }
    return _file.readAsStringSync();
  }

  @override
  File renameSync(String newPath) {
    File newFile = _file.renameSync(newPath);
    provider._moveOverlay(path, newPath);
    return _OverlayFile(provider, newFile);
  }

  @override
  ResourceWatcher watch() => _file.watch();

  @override
  void writeAsBytesSync(List<int> bytes) {
    writeAsStringSync(String.fromCharCodes(bytes));
  }

  @override
  void writeAsStringSync(String content) {
    if (provider.hasOverlay(path)) {
      throw FileSystemException(path, 'Cannot write a file with an overlay');
    }
    _file.writeAsStringSync(content);
  }
}

/// Overlay data for a file.
class _OverlayFileData {
  final String content;
  final int modificationStamp;

  _OverlayFileData(this.content, this.modificationStamp);
}

/// A folder from an [OverlayResourceProvider].
class _OverlayFolder extends _OverlayResource implements Folder {
  /// Initialize a newly created folder to have the given [provider] and to
  /// correspond to the given [folder] from the provider's base resource
  /// provider.
  _OverlayFolder(super.provider, Folder super.folder);

  @Deprecated('Use watch() instead')
  @override
  Stream<WatchEvent> get changes => watch().changes;

  @override
  bool get exists => provider._hasOverlayIn(path) || _resource.exists;

  @override
  bool get isRoot {
    var parentPath = provider.pathContext.dirname(path);
    return parentPath == path;
  }

  /// Return the folder from the base resource provider that corresponds to this
  /// folder.
  Folder get _folder => _resource as Folder;

  @override
  String canonicalizePath(String relPath) {
    pathos.Context context = provider.pathContext;
    relPath = context.normalize(relPath);
    String childPath = context.join(path, relPath);
    childPath = context.normalize(childPath);
    return childPath;
  }

  @override
  bool contains(String path) => _folder.contains(path);

  @override
  Folder copyTo(Folder parentFolder) {
    Folder destination = parentFolder.getChildAssumingFolder(shortName);
    destination.create();
    for (Resource child in getChildren()) {
      child.copyTo(destination);
    }
    return destination;
  }

  @override
  void create() {
    _folder.create();
  }

  @override
  Resource getChild(String relPath) =>
      _OverlayResource._from(provider, _folder.getChild(relPath));

  @override
  File getChildAssumingFile(String relPath) =>
      _OverlayFile(provider, _folder.getChildAssumingFile(relPath));

  @override
  Folder getChildAssumingFolder(String relPath) =>
      _OverlayFolder(provider, _folder.getChildAssumingFolder(relPath));

  @override
  List<Resource> getChildren() {
    Map<String, Resource> children = {};
    try {
      for (final child in _folder.getChildren()) {
        children[child.path] = _OverlayResource._from(provider, child);
      }
    } on FileSystemException {
      // We don't want to throw if we're a folder that only exists in the
      // overlay and not on disk.
    }

    for (String overlayPath in provider._overlaysInFolder(path)) {
      pathos.Context context = provider.pathContext;
      if (context.dirname(overlayPath) == path) {
        children.putIfAbsent(overlayPath, () => provider.getFile(overlayPath));
      } else {
        String relativePath = context.relative(overlayPath, from: path);
        String folderName = context.split(relativePath)[0];
        String folderPath = context.join(path, folderName);
        children.putIfAbsent(folderPath, () => provider.getFolder(folderPath));
      }
    }
    return children.values.toList();
  }

  @override
  ResourceWatcher watch() => _folder.watch();
}

/// The base class for resources from an [OverlayResourceProvider].
abstract class _OverlayResource implements Resource {
  @override
  final OverlayResourceProvider provider;

  /// The resource from the provider's base provider that corresponds to this
  /// resource.
  final Resource _resource;

  /// Initialize a newly created instance of a resource to have the given
  /// [provider] and to represent the [_resource] from the provider's base
  /// resource provider.
  _OverlayResource(this.provider, this._resource);

  /// Return an instance of the subclass of this class corresponding to the
  /// given [resource] that is associated with the given [provider].
  factory _OverlayResource._from(
      OverlayResourceProvider provider, Resource resource) {
    if (resource is Folder) {
      return _OverlayFolder(provider, resource);
    } else if (resource is File) {
      return _OverlayFile(provider, resource);
    }
    throw ArgumentError('Unknown resource type: ${resource.runtimeType}');
  }

  @override
  int get hashCode => path.hashCode;

  @override
  Folder get parent {
    var parent = _resource.parent;
    return _OverlayFolder(provider, parent);
  }

  @override
  Folder get parent2 => parent;

  @override
  String get path => _resource.path;

  @override
  String get shortName => _resource.shortName;

  @override
  bool operator ==(Object other) {
    if (runtimeType != other.runtimeType) {
      return false;
    }
    return path == (other as _OverlayResource).path;
  }

  @override
  void delete() {
    _resource.delete();
  }

  @override
  bool isOrContains(String path) {
    return _resource.isOrContains(path);
  }

  @override
  Resource resolveSymbolicLinksSync() {
    try {
      var resolved = _resource.resolveSymbolicLinksSync();
      return _OverlayResource._from(provider, resolved);
    } catch (_) {
      if (provider.hasOverlay(path) || provider._hasOverlayIn(path)) {
        return this;
      }
      rethrow;
    }
  }

  @override
  String toString() => path;

  @override
  Uri toUri() => _resource.toUri();
}
