// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';
import 'package:meta/meta.dart';

class PackageBundleBuilder {
  final List<PackageBundleLibrary> _libraries = [];

  void addLibrary(String uriStr, List<String> unitUriStrList) {
    _libraries.add(
      PackageBundleLibrary(
        uriStr,
        unitUriStrList.map((e) => PackageBundleUnit(e)).toList(),
      ),
    );
  }

  Uint8List finish({
    required Uint8List resolutionBytes,
    PackageBundleSdk? sdk,
  }) {
    var byteSink = ByteSink();
    var sink = BufferedSink(byteSink);

    if (sdk != null) {
      sink.writeByte(1);
      sdk._write(sink);
    } else {
      sink.writeByte(0);
    }

    sink.writeList(_libraries, (PackageBundleLibrary library) {
      sink.writeStringUtf8(library.uriStr);
      sink.writeList(
        library.units,
        (PackageBundleUnit unit) => sink.writeStringUtf8(unit.uriStr),
      );
    });

    sink.writeUint8List(resolutionBytes);

    return sink.flushAndTake();
  }
}

@internal
class PackageBundleLibrary {
  final String uriStr;
  final List<PackageBundleUnit> units;

  PackageBundleLibrary(this.uriStr, this.units);
}

class PackageBundleReader {
  final List<PackageBundleLibrary> libraries = [];
  late final PackageBundleSdk? _sdk;
  late final Uint8List _resolutionBytes;

  PackageBundleReader(Uint8List bytes) {
    var reader = SummaryDataReader(bytes);

    var hasSdk = reader.readByte() != 0;
    if (hasSdk) {
      _sdk = PackageBundleSdk._fromReader(reader);
    }

    var librariesLength = reader.readUInt30();
    for (var i = 0; i < librariesLength; i++) {
      var uriStr = reader.readStringUtf8();
      var unitsLength = reader.readUInt30();
      var units = List.generate(unitsLength, (_) {
        var uriStr = reader.readStringUtf8();
        return PackageBundleUnit(uriStr);
      });
      libraries.add(
        PackageBundleLibrary(uriStr, units),
      );
    }

    _resolutionBytes = reader.readUint8List();
  }

  Uint8List get resolutionBytes => _resolutionBytes;

  PackageBundleSdk? get sdk => _sdk;
}

class PackageBundleSdk {
  final int languageVersionMajor;
  final int languageVersionMinor;

  /// The content of the `allowed_experiments.json` from SDK.
  final String allowedExperimentsJson;

  PackageBundleSdk({
    required this.languageVersionMajor,
    required this.languageVersionMinor,
    required this.allowedExperimentsJson,
  });

  factory PackageBundleSdk._fromReader(SummaryDataReader reader) {
    return PackageBundleSdk(
      languageVersionMajor: reader.readUInt30(),
      languageVersionMinor: reader.readUInt30(),
      allowedExperimentsJson: reader.readStringUtf8(),
    );
  }

  void _write(BufferedSink sink) {
    sink.writeUInt30(languageVersionMajor);
    sink.writeUInt30(languageVersionMinor);
    sink.writeStringUtf8(allowedExperimentsJson);
  }
}

@internal
class PackageBundleUnit {
  final String uriStr;

  PackageBundleUnit(this.uriStr);
}
