// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: uri_has_not_been_generated,undefined_identifier

/// Common platform independent benchmark infrastructure that can run
/// both on the VM and when compiled to JavaScript.
library common;

import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:protobuf/protobuf.dart';

import 'temp/benchmarks.pb.dart';
import 'temp/datasets/google_message1/proto2/benchmark_message1_proto2.pb.dart'
    as p2;
import 'temp/datasets/google_message1/proto3/benchmark_message1_proto3.pb.dart'
    as p3;
import 'temp/datasets/google_message2/benchmark_message2.pb.dart';
import 'temp/datasets/google_message3/benchmark_message3.pb.dart';
import 'temp/datasets/google_message4/benchmark_message4.pb.dart';

final datasetFiles = [
  'datasets/google_message1/proto3/dataset.google_message1_proto3.pb',
  'datasets/google_message1/proto2/dataset.google_message1_proto2.pb',
  'datasets/google_message2/dataset.google_message2.pb'
];

/// Represents a dataset, a list of protobufs payloads, used for benchmarking.
/// All payloads are instances of the same message.
/// Datasets are loaded from BenchmarkDataset proto (see benchmark.proto).
class Dataset {
  final String name;

  /// Functions that can deserialize all payloads in this dataset.
  final Factories factories;

  /// List of packed payloads, which can be deserialized using [factories].
  final List<Uint8List> packed = <Uint8List>[];

  /// Messages deserialized from [packed] and then serialized back into JSON.
  /// Used for JSON serialization benchmarks.
  final List<String> asJson = <String>[];

  /// Messages deserialized from [packed] and then serialized back into proto3
  /// JSON object. Used for proto3 JSON serialization benchmarks.
  final List<Object> asProto3JsonObject = <Object>[];

  /// Messages deserialized from [packed] and then serialized back into proto3
  /// JSON string. Used for proto3 JSON serialization benchmarks.
  final List<String> asProto3JsonString = <String>[];

  /// Messages deserialized from [packed]. Used in serialization benchmarks.
  final List<GeneratedMessage> unpacked = <GeneratedMessage>[];

  /// Create [Dataset] from a `BenchmarkDataset` proto.
  factory Dataset.fromBinary(List<int> binary) {
    final dataSet = BenchmarkDataset.fromBuffer(binary);

    final factories = Factories.forMessage(dataSet.messageName);
    final ds = Dataset._(dataSet.name, factories);

    for (var payload in dataSet.payload) {
      final bytes = Uint8List.fromList(payload);
      final msg = factories.fromBuffer(bytes);
      ds.packed.add(bytes);
      ds.unpacked.add(msg);
      ds.asJson.add(msg.writeToJson());
      final proto3Json = msg.toProto3Json();
      ds.asProto3JsonObject.add(proto3Json);
      ds.asProto3JsonString.add(jsonEncode(proto3Json));
    }

    return ds;
  }

  Dataset._(this.name, this.factories);
}

typedef FromBufferFactory = dynamic Function(List<int> binary);
typedef FromJsonFactory = dynamic Function(String json);
typedef FromProto3JsonStringFactory = dynamic Function(String json);
typedef FromProto3JsonObjectFactory = dynamic Function(Object json);

class Factories {
  final FromBufferFactory fromBuffer;
  final FromJsonFactory fromJson;
  final FromProto3JsonStringFactory fromProto3JsonString;
  final FromProto3JsonObjectFactory fromProto3JsonObject;

  static Factories forMessage(String name) =>
      _factories[name] ?? (throw 'Unsupported message: $name');

  /// Mapping between `BenchmarkDataset.messageName` and corresponding
  /// deserialization factories.
  static final _factories = {
    'benchmarks.proto2.GoogleMessage1': Factories._(
        fromBuffer: (List<int> binary) => p2.GoogleMessage1.fromBuffer(binary),
        fromJson: (String json) => p2.GoogleMessage1.fromJson(json),
        fromProto3JsonString: (String json) =>
            p2.GoogleMessage1.create()..mergeFromProto3Json(jsonDecode(json)),
        fromProto3JsonObject: (Object json) =>
            p2.GoogleMessage1.create()..mergeFromProto3Json(json)),
    'benchmarks.proto3.GoogleMessage1': Factories._(
        fromBuffer: (List<int> binary) => p3.GoogleMessage1.fromBuffer(binary),
        fromJson: (String json) => p3.GoogleMessage1.fromJson(json),
        fromProto3JsonString: (String json) =>
            p3.GoogleMessage1.create()..mergeFromProto3Json(jsonDecode(json)),
        fromProto3JsonObject: (Object json) =>
            p3.GoogleMessage1.create()..mergeFromProto3Json(json)),
    'benchmarks.proto2.GoogleMessage2': Factories._(
        fromBuffer: (List<int> binary) => GoogleMessage2.fromBuffer(binary),
        fromJson: (String json) => GoogleMessage2.fromJson(json),
        fromProto3JsonString: (String json) =>
            GoogleMessage2.create()..mergeFromProto3Json(jsonDecode(json)),
        fromProto3JsonObject: (Object json) =>
            GoogleMessage2.create()..mergeFromProto3Json(json)),
    'benchmarks.google_message3.GoogleMessage3': Factories._(
        fromBuffer: (List<int> binary) => GoogleMessage3.fromBuffer(binary),
        fromJson: (String json) => GoogleMessage3.fromJson(json),
        fromProto3JsonString: (String json) =>
            GoogleMessage3.create()..mergeFromProto3Json(jsonDecode(json)),
        fromProto3JsonObject: (Object json) =>
            GoogleMessage3.create()..mergeFromProto3Json(json)),
    'benchmarks.google_message4.GoogleMessage4': Factories._(
        fromBuffer: (List<int> binary) => GoogleMessage4.fromBuffer(binary),
        fromJson: (String json) => GoogleMessage4.fromJson(json),
        fromProto3JsonString: (String json) =>
            GoogleMessage4.create()..mergeFromProto3Json(jsonDecode(json)),
        fromProto3JsonObject: (Object json) =>
            GoogleMessage4.create()..mergeFromProto3Json(json)),
  };

  Factories._(
      {required this.fromBuffer,
      required this.fromJson,
      required this.fromProto3JsonString,
      required this.fromProto3JsonObject});
}

/// Base for all protobuf benchmarks.
abstract class _ProtobufBenchmark extends BenchmarkBase {
  final List<Dataset> datasets;

  _ProtobufBenchmark(this.datasets, String name) : super(name);
}

/// Binary deserialization benchmark.
class FromBinaryBenchmark extends _ProtobufBenchmark {
  FromBinaryBenchmark(datasets) : super(datasets, 'FromBinary');

  @override
  void run() {
    for (var i = 0; i < datasets.length; i++) {
      final ds = datasets[i];
      final f = ds.factories.fromBuffer;
      for (var j = 0; j < ds.packed.length; j++) {
        f(ds.packed[j]);
      }
    }
  }
}

/// Binary serialization benchmark.
class ToBinaryBenchmark extends _ProtobufBenchmark {
  ToBinaryBenchmark(datasets) : super(datasets, 'ToBinary');

  @override
  void run() {
    for (final ds in datasets) {
      for (final unpacked in ds.unpacked) {
        unpacked.writeToBuffer();
      }
    }
  }
}

/// JSON deserialization benchmark.
class FromJsonBenchmark extends _ProtobufBenchmark {
  FromJsonBenchmark(datasets) : super(datasets, 'FromJson');

  @override
  void run() {
    for (final ds in datasets) {
      final f = ds.factories.fromJson;
      for (final jsonStr in ds.asJson) {
        f(jsonStr);
      }
    }
  }
}

/// JSON serialization benchmark.
class ToJsonBenchmark extends _ProtobufBenchmark {
  ToJsonBenchmark(datasets) : super(datasets, 'ToJson');

  @override
  void run() {
    for (final ds in datasets) {
      for (final unpacked in ds.unpacked) {
        unpacked.writeToJson();
      }
    }
  }
}

/// proto3 JSON deserialization benchmark: from JSON string to message.
class FromProto3JsonStringBenchmark extends _ProtobufBenchmark {
  FromProto3JsonStringBenchmark(datasets)
      : super(datasets, 'FromProto3JsonString');

  @override
  void run() {
    for (final ds in datasets) {
      final f = ds.factories.fromProto3JsonString;
      for (final jsonStr in ds.asProto3JsonString) {
        f(jsonStr);
      }
    }
  }
}

/// proto3 JSON serialization benchmark: from message to JSON string.
class ToProto3JsonStringBenchmark extends _ProtobufBenchmark {
  ToProto3JsonStringBenchmark(datasets) : super(datasets, 'ToProto3JsonString');

  @override
  void run() {
    for (final ds in datasets) {
      for (final unpacked in ds.unpacked) {
        jsonEncode(unpacked.toProto3Json());
      }
    }
  }
}

/// proto3 JSON deserialization benchmark: from JSON object to message.
class FromProto3JsonObjectBenchmark extends _ProtobufBenchmark {
  FromProto3JsonObjectBenchmark(datasets)
      : super(datasets, 'FromProto3JsonObject');

  @override
  void run() {
    for (final ds in datasets) {
      final f = ds.factories.fromProto3JsonObject;
      for (final jsonObj in ds.asProto3JsonObject) {
        f(jsonObj);
      }
    }
  }
}

/// proto3 JSON serialization benchmark: from message to JSON object.
class ToProto3JsonObjectBenchmark extends _ProtobufBenchmark {
  ToProto3JsonObjectBenchmark(datasets) : super(datasets, 'ToProto3JsonObject');

  @override
  void run() {
    for (final ds in datasets) {
      for (final unpacked in ds.unpacked) {
        unpacked.toProto3Json();
      }
    }
  }
}

/// HashCode computation benchmark.
class HashCodeBenchmark extends _ProtobufBenchmark {
  HashCodeBenchmark(datasets) : super(datasets, 'HashCode');

  @override
  void run() {
    for (final dataset in datasets) {
      for (final unpacked in dataset.unpacked) {
        unpacked.hashCode;
      }
    }
  }
}

void run(List<Dataset> datasets) {
  FromBinaryBenchmark(datasets).report();
  ToBinaryBenchmark(datasets).report();
  FromJsonBenchmark(datasets).report();
  ToJsonBenchmark(datasets).report();
  FromProto3JsonStringBenchmark(datasets).report();
  ToProto3JsonStringBenchmark(datasets).report();
  FromProto3JsonObjectBenchmark(datasets).report();
  ToProto3JsonObjectBenchmark(datasets).report();
  HashCodeBenchmark(datasets).report();
}
