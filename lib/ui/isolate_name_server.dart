// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.ui;

/// Contains methods to allow for simple sharing of SendPorts across isolates.
abstract class IsolateNameServer {
  /// Looks up the [SendPort] associated with a given name. Returns null
  /// if the name does not exist.
  ///
  /// `name` must not be null.
  static SendPort lookupPortByName(String name) {
    assert(name != null, "'name' cannot be null.");
    return _lookupPortByName(name);
  }

  /// Registers a SendPort with a given name. Returns true if registration is
  /// successful, false if the name entry already exists.
  ///
  /// `port` and `name` must not be null.
  static bool registerPortWithName(SendPort port, String name) {
    assert(port != null, "'port' cannot be null.");
    assert(name != null, "'name' cannot be null.");
    return _registerPortWithName(port, name);
  }

  /// Removes a name to SendPort mapping given a name. Returns true if the
  /// mapping was successfully removed, false if the mapping does not exist.
  ///
  /// `name` must not be null.
  static bool removePortNameMapping(String name) {
    assert(name != null, "'name' cannot be null.");
    return _removePortNameMapping(name);
  }

  static SendPort _lookupPortByName(String name)
      native 'IsolateNameServerNatives_LookupPortByName';
  static bool _registerPortWithName(SendPort port, String name)
      native 'IsolateNameServerNatives_RegisterPortWithName';
  static bool _removePortNameMapping(String name)
      native 'IsolateNameServerNatives_RemovePortNameMapping';
}
