// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A minimal AT-SPI client, used to inspect the app as a screen reader would.
library;

import 'dart:async';

import 'package:dbus/dbus.dart';
import 'package:meta/meta.dart';

const String _accessibleInterface = 'org.a11y.atspi.Accessible';
const String _actionInterface = 'org.a11y.atspi.Action';
const String _editableTextInterface = 'org.a11y.atspi.EditableText';
const String _textInterface = 'org.a11y.atspi.Text';
const String _valueInterface = 'org.a11y.atspi.Value';

/// AT-SPI state names, indexed by their value in the AtspiStateType enum.
const List<String> _stateNames = <String>[
  'invalid',
  'active',
  'armed',
  'busy',
  'checked',
  'collapsed',
  'defunct',
  'editable',
  'enabled',
  'expandable',
  'expanded',
  'focusable',
  'focused',
  'has-tooltip',
  'horizontal',
  'iconified',
  'modal',
  'multi-line',
  'multiselectable',
  'opaque',
  'pressed',
  'resizable',
  'selectable',
  'selected',
  'sensitive',
  'showing',
  'single-line',
  'stale',
  'transient',
  'vertical',
  'visible',
  'manages-descendants',
  'indeterminate',
  'required',
  'truncated',
  'animated',
  'invalid-entry',
  'supports-autocompletion',
  'selectable-text',
  'is-default',
  'visited',
  'checkable',
  'has-popup',
  'read-only',
];

/// A connection to the AT-SPI accessibility bus.
class AtspiClient {
  AtspiClient._(this._bus);

  final DBusClient _bus;

  /// Connects to the accessibility bus of the current session.
  static Future<AtspiClient> connect() async {
    final session = DBusClient.session();
    try {
      final DBusMethodSuccessResponse response = await session.callMethod(
        destination: 'org.a11y.Bus',
        path: DBusObjectPath('/org/a11y/bus'),
        interface: 'org.a11y.Bus',
        name: 'GetAddress',
        replySignature: DBusSignature('s'),
      );
      return AtspiClient._(DBusClient(DBusAddress(response.values[0].asString())));
    } finally {
      await session.close();
    }
  }

  /// The desktop, which has the running applications as children.
  AtspiAccessible get desktop => AtspiAccessible._(
    this,
    'org.a11y.atspi.Registry',
    DBusObjectPath('/org/a11y/atspi/accessible/root'),
  );

  /// Waits for an application with [name] to appear on the desktop.
  Future<AtspiAccessible> waitForApplication(
    String name, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final DateTime end = DateTime.now().add(timeout);
    while (true) {
      for (final AtspiAccessible application in await desktop.getChildren()) {
        try {
          if (await application.getName() == name) {
            return application;
          }
        } on DBusMethodResponseException {
          // Ignore applications that have gone away.
        }
      }
      if (DateTime.now().isAfter(end)) {
        throw TimeoutException('Application $name not found on the AT-SPI desktop');
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Requests [event] (e.g. 'object:state-changed') be sent by applications.
  ///
  /// Applications only emit events that have a registered listener.
  Future<void> registerEvent(String event) async {
    await _bus.callMethod(
      destination: 'org.a11y.atspi.Registry',
      path: DBusObjectPath('/org/a11y/atspi/registry'),
      interface: 'org.a11y.atspi.Registry',
      name: 'RegisterEvent',
      values: <DBusValue>[
        DBusString(event),
        DBusArray.string(const <String>[]),
        const DBusString(''),
      ],
      replySignature: DBusSignature.empty,
    );
  }

  /// Gets the events emitted on the AT-SPI [interface] (e.g. 'Object').
  Stream<AtspiEvent> events(String interface) {
    return DBusSignalStream(_bus, interface: 'org.a11y.atspi.Event.$interface').map(
      (DBusSignal signal) => AtspiEvent._(
        signal.name,
        signal.values[0].asString(),
        AtspiAccessible._(this, signal.sender ?? '', signal.path),
      ),
    );
  }

  /// Closes the connection.
  Future<void> close() => _bus.close();
}

/// An event emitted by an accessible.
class AtspiEvent {
  AtspiEvent._(this.name, this.detail, this.source);

  /// The event name, e.g. 'StateChanged'.
  final String name;

  /// The event detail, e.g. the state that changed.
  final String detail;

  /// The accessible that emitted the event.
  final AtspiAccessible source;

  @override
  String toString() => '$name:$detail';
}

/// An accessible object exposed over AT-SPI.
@immutable
class AtspiAccessible {
  const AtspiAccessible._(this._client, this.busName, this.path);

  final AtspiClient _client;

  /// The unique bus name of the application containing this accessible.
  final String busName;

  /// The object path of this accessible.
  final DBusObjectPath path;

  @override
  bool operator ==(Object other) =>
      other is AtspiAccessible && other.busName == busName && other.path == path;

  @override
  int get hashCode => Object.hash(busName, path);

  @override
  String toString() => '$busName:$path';

  Future<List<DBusValue>> _call(
    String interface,
    String name,
    List<DBusValue> values,
    String replySignature,
  ) async {
    final DBusMethodSuccessResponse response = await _client._bus.callMethod(
      destination: busName,
      path: path,
      interface: interface,
      name: name,
      values: values,
      replySignature: DBusSignature(replySignature),
    );
    return response.values;
  }

  Future<DBusValue> _getProperty(String interface, String name) async {
    final List<DBusValue> values = await _call(
      'org.freedesktop.DBus.Properties',
      'Get',
      <DBusValue>[DBusString(interface), DBusString(name)],
      'v',
    );
    return values[0].asVariant();
  }

  Future<void> _setProperty(String interface, String name, DBusValue value) async {
    await _call('org.freedesktop.DBus.Properties', 'Set', <DBusValue>[
      DBusString(interface),
      DBusString(name),
      DBusVariant(value),
    ], '');
  }

  AtspiAccessible _fromReference(DBusValue value) {
    final List<DBusValue> reference = value.asStruct();
    return AtspiAccessible._(_client, reference[0].asString(), reference[1].asObjectPath());
  }

  /// Gets the accessible name.
  Future<String> getName() async => (await _getProperty(_accessibleInterface, 'Name')).asString();

  /// Gets the accessible description.
  Future<String> getDescription() async =>
      (await _getProperty(_accessibleInterface, 'Description')).asString();

  /// Gets the role, e.g. 'push button'.
  Future<String> getRoleName() async =>
      (await _call(_accessibleInterface, 'GetRoleName', <DBusValue>[], 's'))[0].asString();

  /// Gets the child accessibles.
  Future<List<AtspiAccessible>> getChildren() async {
    final List<DBusValue> values = await _call(
      _accessibleInterface,
      'GetChildren',
      <DBusValue>[],
      'a(so)',
    );
    return values[0].asArray().map(_fromReference).toList();
  }

  /// Gets the names of the states this accessible is in.
  Future<Set<String>> getStates() async {
    final List<DBusValue> values = await _call(
      _accessibleInterface,
      'GetState',
      <DBusValue>[],
      'au',
    );
    final List<int> words = values[0].asUint32Array().toList();
    final states = <String>{};
    for (var i = 0; i < _stateNames.length; i++) {
      final int word = i ~/ 32;
      if (word < words.length && (words[word] & (1 << (i % 32))) != 0) {
        states.add(_stateNames[i]);
      }
    }
    return states;
  }

  /// Gets the object attributes.
  Future<Map<String, String>> getAttributes() async {
    final List<DBusValue> values = await _call(
      _accessibleInterface,
      'GetAttributes',
      <DBusValue>[],
      'a{ss}',
    );
    return values[0].asDict().map(
      (DBusValue key, DBusValue value) =>
          MapEntry<String, String>(key.asString(), value.asString()),
    );
  }

  /// Gets the names of the actions that can be performed.
  Future<List<String>> getActionNames() async {
    final DBusValue count = await _getProperty(_actionInterface, 'NActions');
    return <String>[
      for (int i = 0; i < count.asInt32(); i++)
        (await _call(_actionInterface, 'GetName', <DBusValue>[DBusInt32(i)], 's'))[0].asString(),
    ];
  }

  /// Performs the action with [name].
  Future<void> doAction(String name) async {
    final int index = (await getActionNames()).indexOf(name);
    if (index < 0) {
      throw ArgumentError('$this has no action $name');
    }
    await _call(_actionInterface, 'DoAction', <DBusValue>[DBusInt32(index)], 'b');
  }

  /// Gets the current value of a range, e.g. a slider.
  Future<double> getCurrentValue() async =>
      (await _getProperty(_valueInterface, 'CurrentValue')).asDouble();

  /// Gets the minimum value of a range.
  Future<double> getMinimumValue() async =>
      (await _getProperty(_valueInterface, 'MinimumValue')).asDouble();

  /// Gets the maximum value of a range.
  Future<double> getMaximumValue() async =>
      (await _getProperty(_valueInterface, 'MaximumValue')).asDouble();

  /// Sets the current value of a range.
  Future<void> setCurrentValue(double value) =>
      _setProperty(_valueInterface, 'CurrentValue', DBusDouble(value));

  /// Gets the text contents.
  Future<String> getText() async {
    final List<DBusValue> values = await _call(_textInterface, 'GetText', <DBusValue>[
      const DBusInt32(0),
      const DBusInt32(-1),
    ], 's');
    return values[0].asString();
  }

  /// Replaces the text contents with [text].
  Future<void> setTextContents(String text) async {
    await _call(_editableTextInterface, 'SetTextContents', <DBusValue>[DBusString(text)], 'b');
  }

  /// Finds the first descendant (including this) for which [test] is true.
  Future<AtspiAccessible?> find(Future<bool> Function(AtspiAccessible accessible) test) async {
    if (await test(this)) {
      return this;
    }
    for (final AtspiAccessible child in await getChildren()) {
      final AtspiAccessible? result = await child.find(test);
      if (result != null) {
        return result;
      }
    }
    return null;
  }

  /// Finds the first descendant with [name].
  Future<AtspiAccessible> findByName(String name) async {
    final AtspiAccessible? result = await find(
      (AtspiAccessible a) async => await a.getName() == name,
    );
    if (result == null) {
      throw StateError("No '$name' found");
    }
    return result;
  }

  /// Finds the first descendant with [role] and [name].
  Future<AtspiAccessible> findByRole(String role, {String? name}) async {
    final AtspiAccessible? result = await find(
      (AtspiAccessible a) async =>
          await a.getRoleName() == role && (name == null || await a.getName() == name),
    );
    if (result == null) {
      throw StateError('No $role${name != null ? " '$name'" : ''} found');
    }
    return result;
  }
}
