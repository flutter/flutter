// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'html.dart';
import 'streams.dart';
import 'webidl.dart';

typedef BlobPart = JSAny;
typedef EndingType = String;

@JS('Blob')
@staticInterop
class Blob {
  external factory Blob([
    JSArray blobParts,
    BlobPropertyBag options,
  ]);
}

extension BlobExtension on Blob {
  external Blob slice([
    int start,
    int end,
    String contentType,
  ]);
  external ReadableStream stream();
  external JSPromise text();
  external JSPromise arrayBuffer();
  external int get size;
  external String get type;
}

@JS()
@staticInterop
@anonymous
class BlobPropertyBag {
  external factory BlobPropertyBag({
    String type,
    EndingType endings,
  });
}

extension BlobPropertyBagExtension on BlobPropertyBag {
  external set type(String value);
  external String get type;
  external set endings(EndingType value);
  external EndingType get endings;
}

@JS('File')
@staticInterop
class File implements Blob {
  external factory File(
    JSArray fileBits,
    String fileName, [
    FilePropertyBag options,
  ]);
}

extension FileExtension on File {
  external String get name;
  external int get lastModified;
  external String get webkitRelativePath;
}

@JS()
@staticInterop
@anonymous
class FilePropertyBag implements BlobPropertyBag {
  external factory FilePropertyBag({int lastModified});
}

extension FilePropertyBagExtension on FilePropertyBag {
  external set lastModified(int value);
  external int get lastModified;
}

@JS('FileList')
@staticInterop
class FileList {}

extension FileListExtension on FileList {
  external File? item(int index);
  external int get length;
}

@JS('FileReader')
@staticInterop
class FileReader implements EventTarget {
  external factory FileReader();

  external static int get EMPTY;
  external static int get LOADING;
  external static int get DONE;
}

extension FileReaderExtension on FileReader {
  external void readAsArrayBuffer(Blob blob);
  external void readAsBinaryString(Blob blob);
  external void readAsText(
    Blob blob, [
    String encoding,
  ]);
  external void readAsDataURL(Blob blob);
  external void abort();
  external int get readyState;
  external JSAny? get result;
  external DOMException? get error;
  external set onloadstart(EventHandler value);
  external EventHandler get onloadstart;
  external set onprogress(EventHandler value);
  external EventHandler get onprogress;
  external set onload(EventHandler value);
  external EventHandler get onload;
  external set onabort(EventHandler value);
  external EventHandler get onabort;
  external set onerror(EventHandler value);
  external EventHandler get onerror;
  external set onloadend(EventHandler value);
  external EventHandler get onloadend;
}

@JS('FileReaderSync')
@staticInterop
class FileReaderSync {
  external factory FileReaderSync();
}

extension FileReaderSyncExtension on FileReaderSync {
  external JSArrayBuffer readAsArrayBuffer(Blob blob);
  external String readAsBinaryString(Blob blob);
  external String readAsText(
    Blob blob, [
    String encoding,
  ]);
  external String readAsDataURL(Blob blob);
}
