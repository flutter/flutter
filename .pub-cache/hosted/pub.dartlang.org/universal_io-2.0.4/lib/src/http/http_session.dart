// ------------------------------------------------------------------
// THIS FILE WAS DERIVED FROM SOURCE CODE UNDER THE FOLLOWING LICENSE
// ------------------------------------------------------------------
//
// Copyright 2012, the Dart project authors. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Google Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ---------------------------------------------------------
// THIS, DERIVED FILE IS LICENSE UNDER THE FOLLOWING LICENSE
// ---------------------------------------------------------
// Copyright 2020 terrier989@gmail.com.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

part of universal_io.http;

// A _HttpSession is a node in a double-linked list, with _next and _prev being
// the previous and next pointers.
class _HttpSession implements HttpSession {
  // ignore: prefer_final_fields
  bool _isNew = true;
  final DateTime _lastSeen;
  Function? _timeoutCallback;
  final _HttpSessionManager _sessionManager;

  // Pointers in timeout queue.
  _HttpSession? _prev;
  _HttpSession? _next;
  @override
  final String id;

  final Map _data = HashMap();

  _HttpSession(this._sessionManager, this.id) : _lastSeen = DateTime.now();

  @override
  Iterable<MapEntry> get entries => _data.entries;

  // Mark the session as seen. This will reset the timeout and move the node to
  // the end of the timeout queue.
  @override
  bool get isEmpty => _data.isEmpty;

  @override
  bool get isNew => _isNew;

  @override
  bool get isNotEmpty => _data.isNotEmpty;

  @override
  Iterable get keys => _data.keys;

  // Map implementation:
  DateTime get lastSeen => _lastSeen;

  @override
  int get length => _data.length;

  @override
  set onTimeout(void Function() callback) {
    _timeoutCallback = callback;
  }

  @override
  Iterable get values => _data.values;

  @override
  Object? operator [](key) => _data[key];

  @override
  void operator []=(key, value) {
    _data[key] = value;
  }

  @override
  void addAll(Map other) => _data.addAll(other);

  @override
  void addEntries(Iterable<MapEntry> entries) {
    _data.addEntries(entries);
  }

  @override
  Map<K, V> cast<K, V>() => _data.cast<K, V>();

  @override
  void clear() {
    _data.clear();
  }

  @override
  bool containsKey(key) => _data.containsKey(key);

  @override
  bool containsValue(value) => _data.containsValue(value);

  @override
  void destroy() {
    _sessionManager._removeFromTimeoutQueue(this);
    _sessionManager._sessions.remove(id);
  }

  @override
  void forEach(void Function(String key, String value) f) {
    _data.forEach(f as void Function(dynamic, dynamic));
  }

  @override
  Map<K, V> map<K, V>(
          MapEntry<K, V> Function(String key, String value) transform) =>
      _data.map(transform as MapEntry<K, V> Function(dynamic, dynamic));

  @override
  Object putIfAbsent(key, ifAbsent) => _data.putIfAbsent(key, ifAbsent);

  @override
  Object? remove(key) => _data.remove(key);

  @override
  void removeWhere(bool Function(String key, String value) test) {
    _data.removeWhere(test as bool Function(dynamic, dynamic));
  }

  @override
  String toString() => 'HttpSession id:$id $_data';

  @override
  void update(key, void Function(String value) update,
          {Function()? ifAbsent}) =>
      _data.update(key, update as dynamic Function(dynamic),
          ifAbsent: ifAbsent);

  @override
  void updateAll(void Function(String key, String value) update) {
    _data.updateAll(update as dynamic Function(dynamic, dynamic));
  }
}

// Private class used to manage all the active sessions. The sessions are stored
// in two ways:
//
//  * In a map, mapping from ID to HttpSession.
//  * In a linked list, used as a timeout queue.
class _HttpSessionManager {
  final Map<String, _HttpSession> _sessions;
  int _sessionTimeout = 20 * 60; // 20 mins.
  _HttpSession? _head;
  _HttpSession? _tail;
  Timer? _timer;

  _HttpSessionManager() : _sessions = {};

  set sessionTimeout(int timeout) {
    _sessionTimeout = timeout;
    _stopTimer();
    _startTimer();
  }

  void close() {
    _stopTimer();
  }

  _HttpSession createSession() {
    var id = createSessionId();
    // TODO(ajohnsen): Consider adding a limit and throwing an exception.
    // Should be very unlikely however.
    while (_sessions.containsKey(id)) {
      id = createSessionId();
    }
    var session = _sessions[id] = _HttpSession(this, id);
    _addToTimeoutQueue(session);
    return session;
  }

  String createSessionId() {
    const _KEY_LENGTH = 16; // 128 bits.
    var data = _CryptoUtils.getRandomBytes(_KEY_LENGTH);
    return _CryptoUtils.bytesToHex(data);
  }

  _HttpSession? getSession(String? id) => _sessions[id!];

  void _addToTimeoutQueue(_HttpSession session) {
    if (_head == null) {
      assert(_tail == null);
      _tail = _head = session;
      _startTimer();
    } else {
      assert(_timer != null);
      assert(_tail != null);
      // Add to end.
      _tail!._next = session;
      session._prev = _tail;
      _tail = session;
    }
  }

  void _removeFromTimeoutQueue(_HttpSession session) {
    if (session._next != null) {
      session._next!._prev = session._prev;
    }
    if (session._prev != null) {
      session._prev!._next = session._next;
    }
    if (_head == session) {
      // We removed the head element, start new timer.
      _head = session._next;
      _stopTimer();
      _startTimer();
    }
    if (_tail == session) {
      _tail = session._prev;
    }
    session._next = session._prev = null;
  }

  void _startTimer() {
    assert(_timer == null);
    if (_head != null) {
      var seconds = DateTime.now().difference(_head!.lastSeen).inSeconds;
      _timer =
          Timer(Duration(seconds: _sessionTimeout - seconds), _timerTimeout);
    }
  }

  void _stopTimer() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  void _timerTimeout() {
    _stopTimer(); // Clear timer.
    assert(_head != null);
    var session = _head!;
    session.destroy(); // Will remove the session from timeout queue and map.
    if (session._timeoutCallback != null) {
      session._timeoutCallback!();
    }
  }
}
