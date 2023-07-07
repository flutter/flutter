// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of protobuf;

/// Unpacks the message in [value] into [instance].
///
/// Throws a [InvalidProtocolBufferException] if [typeUrl] does not correspond
/// with the type of [instance].
///
/// This is a helper method for `Any.unpackInto`.
void unpackIntoHelper<T extends GeneratedMessage>(
    List<int> value, T instance, String typeUrl,
    {ExtensionRegistry extensionRegistry = ExtensionRegistry.EMPTY}) {
  // From "google/protobuf/any.proto":
  //
  //   The pack methods provided by protobuf library will by default use
  //   'type.googleapis.com/full.type.name' as the type URL and the unpack
  //   methods only use the fully qualified type name after the last '/'
  //   in the type URL, for example "foo.bar.com/x/y.z" will yield type
  //   name "y.z".
  if (!canUnpackIntoHelper(instance, typeUrl)) {
    var typeName = instance.info_.qualifiedMessageName;
    throw InvalidProtocolBufferException.wrongAnyMessage(
        _typeNameFromUrl(typeUrl), typeName);
  }
  instance.mergeFromBuffer(value, extensionRegistry);
}

/// Returns `true` if the type of [instance] is described by
/// `typeUrl`.
///
/// This is a helper method for `Any.canUnpackInto`.
bool canUnpackIntoHelper(GeneratedMessage instance, String typeUrl) {
  return instance.info_.qualifiedMessageName == _typeNameFromUrl(typeUrl);
}

String _typeNameFromUrl(String typeUrl) {
  var index = typeUrl.lastIndexOf('/');
  return index == -1 ? '' : typeUrl.substring(index + 1);
}
