// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show BASE64;
import 'dart:io';

import 'package:path/path.dart' as path;

import 'dart/package_map.dart';
import 'globals.dart';
import 'observatory.dart';

// A file that has been added to a DevFS.
class DevFSEntry {
  DevFSEntry(this.devicePath, this.file);

  final String devicePath;
  final File file;
	FileStat _fileStat;
	DateTime get lastModified => (_fileStat == null) ? null : _fileStat.modified;
	bool get stillExists {
		_stat();
		return _fileStat.type != FileSystemEntityType.NOT_FOUND;
	}
  bool get isModified {
		if (_fileStat == null) {
			_stat();
			return true;
		}
		FileStat _oldFileStat = _fileStat;
		_stat();
		return _fileStat.modified.isAfter(_oldFileStat.modified);
	}

  void _stat() {
		_fileStat = file.statSync();
	}
}

/// Abstract DevFS operations interface.
abstract class DevFSOperations {
	Future<Uri> create(String fsName);
	Future<dynamic> destroy(String fsName);
  Future<dynamic> writeFile(String fsName, DevFSEntry entry);
	Future<dynamic> writeFiles(String fsName, List<DevFSEntry> entries);
}

/// An implementation of [DevFSOperations] that speaks to the
/// service protocol.
class ServiceProtocolDevFSOperations implements DevFSOperations {
	final Observatory	serviceProtocol;

	ServiceProtocolDevFSOperations(this.serviceProtocol);

  @override
	Future<Uri> create(String fsName) async {
		Response response = await serviceProtocol.createDevFS(fsName);
		return Uri.parse(response['uri']);
	}

  @override
	Future<dynamic> destroy(String fsName) async {
		await serviceProtocol.sendRequest('_deleteDevFS',
																			<String, dynamic> { 'fsName': fsName });
	}

  @override
  Future<dynamic> writeFile(String fsName, DevFSEntry entry) async {
    List<int> bytes;
    try {
      bytes = entry.file.readAsBytesSync();
    } catch (e) {
      printError('DevFS: Failed to read ${entry.file.path} -- $e');
      return;
    }
    String fileContents = BASE64.encode(bytes);
    await serviceProtocol.sendRequest('_writeDevFSFile',
                                      <String, dynamic> {
                                          'fsName': fsName,
                                          'path': entry.devicePath,
                                          'fileContents': fileContents
                                      });
  }

  @override
	Future<dynamic> writeFiles(String fsName, List<DevFSEntry> entries) async {
    List<List<String>> files = new List<List<String>>();
    for (DevFSEntry entry in entries) {
      List<String> file = new List<String>(2);
      file[0] = entry.devicePath;
      List<int> bytes;
      try {
        bytes = entry.file.readAsBytesSync();
      } catch (e) {
        printError('DevFS: Failed to read ${entry.file.path} -- $e');
        continue;
      }
      file[1] = BASE64.encode(bytes);
      files.add(file);
    }
    printTrace('DevFS: _writeDevFSFiles ${files.length}');
    await serviceProtocol.sendRequest('_writeDevFSFiles',
                                      <String, dynamic> { 'fsName': fsName,
                                                          'files': files });
	}
}

class DevFS {
	/// Create a [DevFS] named [fsName] for the local files in [directory].
	DevFS(Observatory serviceProtocol,
				this.fsName,
				this.rootDirectory)
		: _operations = new ServiceProtocolDevFSOperations(serviceProtocol) {
	}

	DevFS.operations(this._operations,
									 this.fsName,
			  			     this.rootDirectory);

  final DevFSOperations _operations;
	final String fsName;
	final Directory rootDirectory;
	final Map<String, DevFSEntry> _entries = <String, DevFSEntry>{};
	final List<DevFSEntry> _dirtyEntries = new List<DevFSEntry>();
	Uri _baseUri;
	Uri get baseUri => _baseUri;

	Future<Uri> create() async {
		_baseUri = await _operations.create(fsName);
		printTrace('DevFS: Created new filesystem with base uri: $_baseUri');
		return _baseUri;
	}

	Future<dynamic> destroy() async {
		return await _operations.destroy(fsName);
	}

	Future<dynamic> populate() async {
		await update();
	}

	Future<dynamic> update() async {
		// Send the root and lib directories.
		Directory directory = rootDirectory;
		_syncDirectory(directory, recursive: true);

		// Send the packages.
		if (FileSystemEntity.isFileSync(kPackagesFileName)) {
			PackageMap packageMap = new PackageMap(kPackagesFileName);

			for (String packageName in packageMap.map.keys) {
				Uri uri = packageMap.map[packageName];
				// Ignore self-references.
				if (uri.toString() == 'lib/')
					continue;
				Directory directory = new Directory.fromUri(uri);
				_syncDirectory(directory,
											 directoryName: 'packages/$packageName',
											 recursive: true);
			}
		}

    printTrace('DevFS: Have ${_dirtyEntries.length} files to sync.');
    for (DevFSEntry entry in _dirtyEntries) {
      printTrace('DevFS: Syncing "${entry.devicePath}"');
    }
    printTrace('DevFS: Sync starting');
    try {
      await _operations.writeFiles(fsName, _dirtyEntries);
    } catch (e) {
      print('error - $e');
    }
    printTrace('DevFS: Sync finished');
    _dirtyEntries.clear();
	}

	void _syncFile(String devicePath, File file) {
		DevFSEntry entry = _entries[devicePath];
		if (entry == null) {
			// New file.
			entry = new DevFSEntry(devicePath, file);
			_entries[devicePath] = entry;
		}
		bool needsWrite = entry.isModified;
		if (needsWrite) {
			printTrace('DevFS: Scheduling "$devicePath" for sync.');
			_dirtyEntries.add(entry);
		}
	}

	void _syncDirectory(Directory directory,
											{String directoryName,
											 bool recursive: false,
										   bool ignoreDotFiles: true}) {
	  String prefix = directoryName;
		if (prefix == null) {
			prefix = path.relative(directory.path, from: rootDirectory.path);
		}
		try {
			List<FileSystemEntity> files =
					directory.listSync(recursive: recursive, followLinks: false);
			for (FileSystemEntity file in files) {
				if (file is! File) {
					// Skip non-files.
					continue;
				}
				if (ignoreDotFiles && path.basename(file.path).startsWith('.')) {
					// Skip dot files.
					continue;
				}
				final String devicePath =
						path.join(prefix, path.relative(file.path, from: directory.path));
				_syncFile(devicePath, file);
			}
		} catch (e) {
			printError('_syncDirectory FAILED for $directory', e);
		}
	}
}
