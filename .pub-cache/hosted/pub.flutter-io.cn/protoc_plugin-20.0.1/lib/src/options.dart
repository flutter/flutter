// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'generated/plugin.pb.dart';

typedef OnError = void Function(String details);

/// Helper function implementing a generic option parser that reads
/// `request.parameters` and treats each token as either a flag ("name") or a
/// key-value pair ("name=value"). For each option "name", it looks up whether a
/// [SingleOptionParser] exists in [parsers] and delegates the actual parsing of
/// the option to it. Returns `true` if no errors were reported.
bool genericOptionsParser(CodeGeneratorRequest request,
    CodeGeneratorResponse response, Map<String, SingleOptionParser> parsers) {
  var parameter = request.parameter;
  var options = parameter.trim().split(',');
  var errors = [];

  for (var option in options) {
    option = option.trim();
    if (option.isEmpty) continue;
    void reportError(String details) {
      errors.add('Error found trying to parse the option: $option.\n$details');
    }

    var nameValue = option.split('=');
    if (nameValue.length != 1 && nameValue.length != 2) {
      reportError('Options should be a single token, or a name=value pair');
      continue;
    }
    var name = nameValue[0].trim();
    var parser = parsers[name];
    if (parser == null) {
      reportError('Unknown option ($name).');
      continue;
    }

    var value = nameValue.length > 1 ? nameValue[1].trim() : null;
    parser.parse(name, value, reportError);
  }

  if (errors.isEmpty) return true;

  response.error = errors.join('\n');
  return false;
}

/// Options expected by the protoc code generation compiler.
class GenerationOptions {
  final bool useGrpc;
  final bool generateMetadata;

  GenerationOptions({this.useGrpc = false, this.generateMetadata = false});
}

/// A parser for a name-value pair option. Options parsed in
/// [genericOptionsParser] delegate to instances of this class to
/// parse the value of a specific option.
abstract class SingleOptionParser {
  /// Parse the [name]=[value] value pair and report any errors to [onError]. If
  /// the option is a flag, [value] will be null. Note, [name] is commonly
  /// unused. It is provided because [SingleOptionParser] can be registered for
  /// multiple option names in [genericOptionsParser].
  void parse(String name, String? value, OnError onError);
}

class GrpcOptionParser implements SingleOptionParser {
  bool grpcEnabled = false;

  @override
  void parse(String name, String? value, OnError onError) {
    if (value != null) {
      onError('Invalid grpc option. No value expected.');
      return;
    }
    grpcEnabled = true;
  }
}

class GenerateMetadataParser implements SingleOptionParser {
  bool generateKytheInfo = false;

  @override
  void parse(String name, String? value, OnError onError) {
    if (value != null) {
      onError('Invalid metadata option. No Value expected.');
      return;
    }
    generateKytheInfo = true;
  }
}

/// Parser used by the compiler, which supports the `rpc` option (see
/// [GrpcOptionParser]) and any additional option added in [parsers]. If
/// [parsers] has a key for `rpc`, it will be ignored.
GenerationOptions? parseGenerationOptions(
    CodeGeneratorRequest request, CodeGeneratorResponse response,
    [Map<String, SingleOptionParser>? parsers]) {
  final newParsers = <String, SingleOptionParser>{};
  if (parsers != null) newParsers.addAll(parsers);

  final grpcOptionParser = GrpcOptionParser();
  newParsers['grpc'] = grpcOptionParser;
  final generateMetadataParser = GenerateMetadataParser();
  newParsers['generate_kythe_info'] = generateMetadataParser;

  if (genericOptionsParser(request, response, newParsers)) {
    return GenerationOptions(
        useGrpc: grpcOptionParser.grpcEnabled,
        generateMetadata: generateMetadataParser.generateKytheInfo);
  }
  return null;
}
