/// Generates UUID v1, v4, v5 following RFC4122 standard.
library uuid;

import 'dart:typed_data';

import 'uuid_util.dart';
import 'package:crypto/crypto.dart' as crypto;

/// uuid for Dart
/// Author: Yulian Kuncheff
/// Released under MIT License.

class Uuid {
  // RFC4122 provided namespaces for v3 and v5 namespace based UUIDs
  static const NAMESPACE_DNS = '6ba7b810-9dad-11d1-80b4-00c04fd430c8';
  static const NAMESPACE_URL = '6ba7b811-9dad-11d1-80b4-00c04fd430c8';
  static const NAMESPACE_OID = '6ba7b812-9dad-11d1-80b4-00c04fd430c8';
  static const NAMESPACE_X500 = '6ba7b814-9dad-11d1-80b4-00c04fd430c8';
  static const NAMESPACE_NIL = '00000000-0000-0000-0000-000000000000';

  // Easy number <-> hex conversion
  static final List<String> _byteToHex = List<String>.generate(256, (i) {
    return i.toRadixString(16).padLeft(2, '0');
  });

  final Map<String, dynamic>? options;

  static final _stateExpando = Expando<Map<String, dynamic>>();
  Map<String, dynamic> get _state => _stateExpando[this] ??= {
        'seedBytes': null,
        'node': null,
        'clockSeq': null,
        'mSecs': 0,
        'nSecs': 0,
        'hasInitV1': false,
        'hasInitV4': false
      };

  const Uuid({this.options});

  /// Validates the provided [uuid] to make sure it has all the necessary
  /// components and formatting and returns a [bool]
  /// You can choose to validate from a string or from a byte list based on
  /// which parameter is passed.
  static bool isValidUUID(
      {String fromString = '',
      Uint8List? fromByteList,
      ValidationMode validationMode = ValidationMode.strictRFC4122}) {
    if (fromByteList != null) {
      fromString = unparse(fromByteList);
    }
    // UUID of all 0s is ok.
    if (fromString == NAMESPACE_NIL) {
      return true;
    }

    // If its not 36 characters in length, don't bother (including dashes).
    if (fromString.length != 36) {
      return false;
    }

    // Make sure if it passes the above, that it's a valid UUID or GUID.
    switch (validationMode) {
      case ValidationMode.strictRFC4122:
        {
          const pattern =
              r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$';
          final regex = RegExp(pattern, caseSensitive: false, multiLine: true);
          final match = regex.hasMatch(fromString);
          return match;
        }
      case ValidationMode.nonStrict:
        {
          const pattern =
              r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-5][0-9a-f]{3}-[0-9a-f]{4}-[0-9a-f]{12}$';
          final regex = RegExp(pattern, caseSensitive: false, multiLine: true);
          final match = regex.hasMatch(fromString);
          return match;
        }
      default:
        {
          throw Exception('`$validationMode` is an invalid ValidationMode.');
        }
    }
  }

  static void isValidOrThrow(
      {String fromString = '',
      Uint8List? fromByteList,
      ValidationMode validationMode = ValidationMode.strictRFC4122}) {
    final isValid = isValidUUID(
        fromString: fromString,
        fromByteList: fromByteList,
        validationMode: validationMode);

    if (!isValid) {
      // let's check if it is a non RFC4122 uuid and help the developer
      if (validationMode != ValidationMode.nonStrict) {
        final isValidNonStrict = isValidUUID(
            fromString: fromString,
            fromByteList: fromByteList,
            validationMode: ValidationMode.nonStrict);

        if (isValidNonStrict) {
          throw FormatException(
              'The provided UUID is not RFC4122 compliant. It seems you might be using a Microsoft GUID. Try setting `validationMode = ValidationMode.nonStrict`',
              fromString);
        }
      }

      throw FormatException('The provided UUID is invalid.', fromString);
    }
  }

  /// Parses the provided [uuid] into a list of byte values as a List<int>.
  ///
  /// Can optionally be provided a [buffer] to write into and
  /// a positional [offset] for where to start inputting into the buffer.
  ///
  /// Returns the buffer containing the bytes. If no buffer was provided,
  /// a new buffer is created and returned. If a _buffer_ was provided, it
  /// is returned (even if the uuid bytes are not placed at the beginning of
  /// that buffer).
  ///
  /// Throws FormatException if the UUID is invalid. Optionally you can set
  /// [validate] to false to disable validation of the UUID before parsing.
  ///
  /// Throws _RangeError_ if a _buffer_ is provided and it is too small.
  /// It is also thrown if a non-zero _offset_ is provided without providing
  /// a _buffer_.
  static List<int> parse(
    String uuid, {
    List<int>? buffer,
    int offset = 0,
    bool validate = true,
    ValidationMode validationMode = ValidationMode.strictRFC4122,
  }) {
    if (validate) {
      isValidOrThrow(fromString: uuid, validationMode: validationMode);
    }
    var i = offset, ii = 0;

    // Get buffer to store the result
    if (buffer == null) {
      // Buffer not provided: create a 16 item buffer
      if (offset != 0) {
        throw RangeError('non-zero offset without providing a buffer');
      }
      buffer = Uint8List(16);
    } else {
      // Buffer provided: check it is large enough
      if (buffer.length - offset < 16) {
        throw RangeError('buffer too small: need 16: length=${buffer.length}'
            '${offset != 0 ? ', offset=$offset' : ''}');
      }
    }

    // Convert to lowercase and replace all hex with bytes then
    // string.replaceAll() does a lot of work that I don't need, and a manual
    // regex gives me more control.
    final regex = RegExp('[0-9a-f]{2}');
    for (Match match in regex.allMatches(uuid.toLowerCase())) {
      if (ii < 16) {
        var hex = uuid.toLowerCase().substring(match.start, match.end);
        buffer[i + ii++] = int.parse(hex, radix: 16);
      }
    }

    // Zero out any left over bytes if the string was too short.
    while (ii < 16) {
      buffer[i + ii++] = 0;
    }

    return buffer;
  }

  ///Parses the provided [uuid] into a list of byte values as a Uint8List.
  /// Can optionally be provided a [buffer] to write into and
  ///  a positional [offset] for where to start inputting into the buffer.
  /// Throws FormatException if the UUID is invalid. Optionally you can set
  /// [validate] to false to disable validation of the UUID before parsing.
  static Uint8List parseAsByteList(String uuid,
      {List<int>? buffer,
      int offset = 0,
      bool validate = true,
      ValidationMode validationMode = ValidationMode.strictRFC4122}) {
    return Uint8List.fromList(parse(uuid,
        buffer: buffer,
        offset: offset,
        validate: validate,
        validationMode: validationMode));
  }

  /// Unparses a [buffer] of bytes and outputs a proper UUID string.
  /// An optional [offset] is allowed if you want to start at a different point
  /// in the buffer.
  ///
  /// Throws a [RangeError] exception if the _buffer_ is not large enough to
  /// hold the bytes. That is, if the length of the _buffer_ after the _offset_
  /// is less than 16.
  static String unparse(List<int> buffer, {int offset = 0}) {
    if (buffer.length - offset < 16) {
      throw RangeError('buffer too small: need 16: length=${buffer.length}'
          '${offset != 0 ? ', offset=$offset' : ''}');
    }
    var i = offset;
    return '${_byteToHex[buffer[i++]]}${_byteToHex[buffer[i++]]}'
        '${_byteToHex[buffer[i++]]}${_byteToHex[buffer[i++]]}-'
        '${_byteToHex[buffer[i++]]}${_byteToHex[buffer[i++]]}-'
        '${_byteToHex[buffer[i++]]}${_byteToHex[buffer[i++]]}-'
        '${_byteToHex[buffer[i++]]}${_byteToHex[buffer[i++]]}-'
        '${_byteToHex[buffer[i++]]}${_byteToHex[buffer[i++]]}'
        '${_byteToHex[buffer[i++]]}${_byteToHex[buffer[i++]]}'
        '${_byteToHex[buffer[i++]]}${_byteToHex[buffer[i++]]}';
  }

  void _initV1() {
    final options = this.options ?? const {};

    if (!(_state['hasInitV1']! as bool)) {
      var v1PositionalArgs = (options['v1rngPositionalArgs'] != null)
          ? options['v1rngPositionalArgs']
          : [];
      var v1NamedArgs = (options['v1rngNamedArgs'] != null)
          ? options['v1rngNamedArgs'] as Map<Symbol, dynamic>
          : const <Symbol, dynamic>{};
      Uint8List seedBytes = (options['v1rng'] != null)
          ? Function.apply(options['v1rng'], v1PositionalArgs, v1NamedArgs)
          : UuidUtil.mathRNG();

      (_state['seedBytes'] != null)
          ? _state['seedBytes']
          : _state['seedBytes'] = seedBytes;

      // Per 4.5, create a 48-bit node id (47 random bits + multicast bit = 1)
      var nodeId = [
        seedBytes[0] | 0x01,
        seedBytes[1],
        seedBytes[2],
        seedBytes[3],
        seedBytes[4],
        seedBytes[5]
      ];
      (_state['node'] != null) ? _state['node'] : _state['node'] = nodeId;

      // Per 4.2.2, randomize (14 bit) clockseq
      var clockSeq = (seedBytes[6] << 8 | seedBytes[7]) & 0x3ffff;
      _state['clockSeq'] ??= clockSeq;

      _state['mSecs'] = 0;
      _state['nSecs'] = 0;
      _state['hasInitV1'] = true;
    }
  }

  void _initV4() {
    final options = this.options ?? const {};

    if (!(_state['hasInitV4']! as bool)) {
      // Set the globalRNG function to mathRNG with the option to set an alternative globally
      var gPositionalArgs = (options['gPositionalArgs'] != null)
          ? options['gPositionalArgs']
          : const [];
      var gNamedArgs = (options['gNamedArgs'] != null)
          ? options['gNamedArgs'] as Map<Symbol, dynamic>
          : const <Symbol, dynamic>{};

      final grng = options['grng'];
      _state['globalRNG'] = (grng != null)
          ? () => Function.apply(grng, gPositionalArgs, gNamedArgs)
          : UuidUtil.mathRNG;

      _state['hasInitV4'] = true;
    }
  }

  /// v1() Generates a time-based version 1 UUID
  ///
  /// By default it will generate a string based off current time, and will
  /// return a string.
  ///
  /// The first argument is an options map that takes various configuration
  /// options detailed in the readme.
  ///
  /// http://tools.ietf.org/html/rfc4122.html#section-4.2.2
  String v1({Map<String, dynamic>? options}) {
    var i = 0;
    var buf = Uint8List(16);
    options ??= {};

    _initV1();
    var clockSeq = options['clockSeq'] != null
        ? options['clockSeq'] as int
        : _state['clockSeq'] as int;

    // UUID timestamps are 100 nano-second units since the Gregorian epoch,
    // (1582-10-15 00:00). Time is handled internally as 'msecs' (integer
    // milliseconds) and 'nsecs' (100-nanoseconds offset from msecs) since unix
    // epoch, 1970-01-01 00:00.
    var mSecs = (options['mSecs'] != null)
        ? (options['mSecs'] as int)
        : DateTime.now().millisecondsSinceEpoch;

    // Per 4.2.1.2, use count of uuid's generated during the current clock
    // cycle to simulate higher resolution clock
    var nSecs = options['nSecs'] != null
        ? (options['nSecs'] as int)
        : (_state['nSecs']! as int) + 1;

    // Time since last uuid creation (in msecs)
    var dt = (mSecs - _state['mSecs']) + (nSecs - _state['nSecs']) / 10000;

    // Per 4.2.1.2, Bump clockseq on clock regression
    if (dt < 0 && options['clockSeq'] == null) {
      clockSeq = clockSeq + 1 & 0x3fff;
    }

    // Reset nsecs if clock regresses (new clockseq) or we've moved onto a new
    // time interval
    if ((dt < 0 || mSecs > _state['mSecs']) && options['nSecs'] == null) {
      nSecs = 0;
    }

    // Per 4.2.1.2 Throw error if too many uuids are requested
    if (nSecs >= 10000) {
      throw Exception('uuid.v1(): Can\'t create more than 10M uuids/sec');
    }

    _state['mSecs'] = mSecs;
    _state['nSecs'] = nSecs;
    _state['clockSeq'] = clockSeq;

    // Per 4.1.4 - Convert from unix epoch to Gregorian epoch
    mSecs += 12219292800000;

    // time Low
    var tl = ((mSecs & 0xfffffff) * 10000 + nSecs) % 0x100000000;
    buf[i++] = tl >> 24 & 0xff;
    buf[i++] = tl >> 16 & 0xff;
    buf[i++] = tl >> 8 & 0xff;
    buf[i++] = tl & 0xff;

    // time mid
    var tmh = (mSecs / 0x100000000 * 10000).floor() & 0xfffffff;
    buf[i++] = tmh >> 8 & 0xff;
    buf[i++] = tmh & 0xff;

    // time high and version
    buf[i++] = tmh >> 24 & 0xf | 0x10; // include version
    buf[i++] = tmh >> 16 & 0xff;

    // clockSeq high and reserved (Per 4.2.2 - include variant)
    buf[i++] = (clockSeq & 0x3F00) >> 8 | 0x80;

    // clockSeq low
    buf[i++] = clockSeq & 0xff;

    // node
    var node = options['node'] != null
        ? options['node'] as List
        : _state['node'] as List;
    for (var n = 0; n < 6; n++) {
      buf[i + n] = node[n];
    }

    return unparse(buf);
  }

  /// v1buffer() Generates a time-based version 1 UUID
  ///
  /// By default it will generate a string based off current time, and will
  /// place the result into the provided [buffer]. The [buffer] will also be returned..
  ///
  /// Optionally an [offset] can be provided with a start position in the buffer.
  ///
  /// The first argument is an options map that takes various configuration
  /// options detailed in the readme.
  ///
  /// http://tools.ietf.org/html/rfc4122.html#section-4.2.2
  List<int> v1buffer(
    List<int> buffer, {
    Map<String, dynamic>? options,
    int offset = 0,
  }) {
    return parse(v1(options: options), buffer: buffer, offset: offset);
  }

  /// v1obj() Generates a time-based version 1 UUID
  ///
  /// By default it will generate a string based off current time, and will
  /// return it as a [UuidValue] object.
  ///
  /// The first argument is an options map that takes various configuration
  /// options detailed in the readme.
  ///
  /// http://tools.ietf.org/html/rfc4122.html#section-4.2.2
  UuidValue v1obj({Map<String, dynamic>? options}) {
    var uuid = v1(options: options);
    return UuidValue(uuid);
  }

  /// v4() Generates a RNG version 4 UUID
  ///
  /// By default it will generate a string based mathRNG, and will return
  /// a string. If you wish to use crypto-strong RNG, pass in UuidUtil.cryptoRNG
  ///
  /// The first argument is an options map that takes various configuration
  /// options detailed in the readme.
  ///
  /// http://tools.ietf.org/html/rfc4122.html#section-4.4
  String v4({Map<String, dynamic>? options}) {
    options ??= {};

    _initV4();
    // Use the built-in RNG or a custom provided RNG
    var positionalArgs =
        (options['positionalArgs'] != null) ? options['positionalArgs'] : [];
    var namedArgs = (options['namedArgs'] != null)
        ? options['namedArgs'] as Map<Symbol, dynamic>
        : const <Symbol, dynamic>{};
    // We cast to 'dynamic Function()' below instead of 'List<int> Function()'
    // as existing code may not return a closure of the correct type.
    var rng = (options['rng'] != null)
        ? Function.apply(options['rng'], positionalArgs, namedArgs) as List<int>
        : (_state['globalRNG']! as dynamic Function())() as List<int>;

    // Use provided values over RNG
    var rnds = options['random'] != null ? options['random'] as List<int> : rng;

    // per 4.4, set bits for version and clockSeq high and reserved
    rnds[6] = (rnds[6] & 0x0f) | 0x40;
    rnds[8] = (rnds[8] & 0x3f) | 0x80;

    return unparse(rnds);
  }

  /// v4buffer() Generates a RNG version 4 UUID
  ///
  /// By default it will generate a string based off mathRNG, and will
  /// place the result into the provided [buffer]. The [buffer] will also be returned.
  /// If you wish to have crypto-strong RNG, pass in UuidUtil.cryptoRNG.
  ///
  /// Optionally an [offset] can be provided with a start position in the buffer.
  ///
  /// The first argument is an options map that takes various configuration
  /// options detailed in the readme.
  ///
  /// http://tools.ietf.org/html/rfc4122.html#section-4.4
  List<int> v4buffer(
    List<int> buffer, {
    Map<String, dynamic>? options,
    int offset = 0,
  }) {
    return parse(v4(options: options), buffer: buffer, offset: offset);
  }

  /// v4obj() Generates a RNG version 4 UUID
  ///
  /// By default it will generate a string based mathRNG, and will return
  /// a [UuidValue] object. If you wish to use crypto-strong RNG, pass in UuidUtil.cryptoRNG
  ///
  /// The first argument is an options map that takes various configuration
  /// options detailed in the readme.
  ///
  /// http://tools.ietf.org/html/rfc4122.html#section-4.4
  UuidValue v4obj({Map<String, dynamic>? options}) {
    var uuid = v4(options: options);
    return UuidValue(uuid);
  }

  /// v5() Generates a namespace & name-based version 5 UUID
  ///
  /// By default it will generate a string based on a provided uuid namespace and
  /// name, and will return a string.
  ///
  /// The first argument is an options map that takes various configuration
  /// options detailed in the readme.
  ///
  /// http://tools.ietf.org/html/rfc4122.html#section-4.4
  String v5(String? namespace, String? name, {Map<String, dynamic>? options}) {
    options ??= {};

    // Check if user wants a random namespace generated by v4() or a NIL namespace.
    var useRandom = (options['randomNamespace'] != null)
        ? options['randomNamespace']
        : true;

    // If useRandom is true, generate UUIDv4, else use NIL
    var blankNS = useRandom ? v4() : NAMESPACE_NIL;

    // Use provided namespace, or use whatever is decided by options.
    namespace = (namespace != null) ? namespace : blankNS;

    // Use provided name,
    name = (name != null) ? name : '';

    // Convert namespace UUID to Byte List
    var bytes = parse(namespace);

    // Convert name to a list of bytes
    var nameBytes = <int>[];
    for (var singleChar in name.codeUnits) {
      nameBytes.add(singleChar);
    }

    // Generate SHA1 using namespace concatenated with name
    var hashBytes = crypto.sha1.convert([...bytes, ...nameBytes]).bytes;

    // per 4.4, set bits for version and clockSeq high and reserved
    hashBytes[6] = (hashBytes[6] & 0x0f) | 0x50;
    hashBytes[8] = (hashBytes[8] & 0x3f) | 0x80;

    return unparse(hashBytes.sublist(0, 16));
  }

  /// v5buffer() Generates a RNG version 4 UUID
  ///
  /// By default it will generate a string based off current time, and will
  /// place the result into the provided [buffer]. The [buffer] will also be returned..
  ///
  /// Optionally an [offset] can be provided with a start position in the buffer.
  ///
  /// The first argument is an options map that takes various configuration
  /// options detailed in the readme.
  ///
  /// http://tools.ietf.org/html/rfc4122.html#section-4.4
  List<int> v5buffer(
    String? namespace,
    String? name,
    List<int>? buffer, {
    Map<String, dynamic>? options,
    int offset = 0,
  }) {
    return parse(v5(namespace, name, options: options),
        buffer: buffer, offset: offset);
  }

  /// v5obj() Generates a namspace & name-based version 5 UUID
  ///
  /// By default it will generate a string based on a provided uuid namespace and
  /// name, and will return a [UuidValue] object.
  ///
  /// The first argument is an options map that takes various configuration
  /// options detailed in the readme.
  ///
  /// http://tools.ietf.org/html/rfc4122.html#section-4.4
  UuidValue v5obj(String? namespace, String? name,
      {Map<String, dynamic>? options}) {
    var uuid = v5(namespace, name, options: options);
    return UuidValue(uuid);
  }
}

enum ValidationMode { nonStrict, strictRFC4122 }

class UuidValue {
  final String uuid;

  /// UuidValue() Constructor for creating a uuid value.
  ///
  /// Takes in a string representation of a [uuid] to wrap.
  ///
  /// Optionally , you can disable the validation check in the constructor
  /// by setting [validate] to `false`.
  factory UuidValue(String uuid,
      [bool validate = true,
      ValidationMode validationMode = ValidationMode.strictRFC4122]) {
    if (validate) {
      Uuid.isValidOrThrow(fromString: uuid, validationMode: validationMode);
    }

    return UuidValue._(uuid.toLowerCase());
  }

  factory UuidValue.fromByteList(Uint8List byteList, {int? offset}) {
    return UuidValue(Uuid.unparse(byteList, offset: offset ?? 0));
  }

  factory UuidValue.fromList(List<int> byteList, {int? offset}) {
    return UuidValue(Uuid.unparse(byteList, offset: offset ?? 0));
  }

  UuidValue._(this.uuid);

  // toBytes() converts the internal string representation to a list of bytes.
  Uint8List toBytes() {
    return Uuid.parseAsByteList(uuid);
  }

  // toString() returns the String representation of the UUID
  @override
  String toString() {
    return uuid;
  }

  // equals() compares to UuidValue objects' uuids.
  bool equals(UuidValue other) {
    return uuid == other.uuid;
  }

  @override
  bool operator ==(Object other) => other is UuidValue && uuid == other.uuid;

  @override
  int get hashCode => uuid.hashCode;
}
