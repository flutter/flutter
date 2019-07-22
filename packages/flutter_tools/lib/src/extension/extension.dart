// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Core types used to communicate with the flutter tool.
library extension;

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import 'app.dart';
import 'build.dart';
import 'device.dart';
import 'doctor.dart';

/// A request sent to a tool extension from the host.
class Request {
  /// Create a new [Request] object.
  const Request(this.id, this.method, this.arguments);

  /// Create a new [Request] object from a json object.
  factory Request.fromJson(Map<String, Object> json) {
    final int id =  json['id'];
    final Map<String, Object> arguments = json['arguments'];
    final String method = json['method'];
    return Request(
      id,
      method,
      arguments,
    );
  }

  /// The unique identifier of this request.
  ///
  /// The id of the corresponding [Response] will match this value.
  final int id;

  /// JSON serialized request values.
  final Map<String, Object> arguments;

  /// The name of this request method.
  final String method;

  /// Convert into a JSON serializable object.
  Map<String, Object> toJson() {
    return <String, Object>{
      'method': method,
      'id': id,
      'arguments': arguments,
    };
  }
}

/// A response sent from a tool extension to the host.
class Response {
  /// Create a new [Response] object.
  const Response(this.id, this.body, [ this.error ]);

  /// Create a new [Response] object from a json object.
  factory Response.fromJson(Map<String, Object> json) {
    final int id = json['id'];
    final Map<String, Object> body = json['body'];
    final Map<String, Object> error = json['error'];
    return Response(
      id,
      body,
      error,
    );
  }

  /// The unique identifier of this response.
  ///
  /// Matches the corresponding request.
  final int id;

  /// The JSON serialized response values, or null if there was an error.
  final Map<String, Object> body;

  /// The JSON serializes error, or null if it was successful.
  final Map<String, Object> error;

  /// Whether this response has an error attached.
  bool get hasError => error != null;

  /// Convert into a JSON serializable object.
  Map<String, Object> toJson() {
    return <String, Object>{
      'id': id,
      'body': body,
      'error': error,
    };
  }
}

/// A type that can be converted into a JSON-safe object.
abstract class Serializable {
  /// Convert this object to a JSON-safe object.
  Object toJson();
}

/// A callback used to respond to an extension request.
typedef DomainHandler = Future<Serializable> Function(Map<String, Object>);

/// An extension is a pluggable piece of tool functionality.
///
/// New extension functionaliy should be implemented by extending this class
/// and overriding [doctorDomain], [deviceDomain], and/or [appDomain] to inject
/// the required functionality.
abstract class ToolExtension {
  ToolExtension() {
    if (doctorDomain != null) {
      doctorDomain._parent = this;
      registerMethod('doctor.diagnose', (Map<String, Object> args) => doctorDomain.diagnose());
    }
    if (deviceDomain != null) {
      deviceDomain._parent = this;
      registerMethod('device.listDevices', (Map<String, Object> args) => deviceDomain.listDevices());
    }
    if (appDomain != null) {
      appDomain._parent = this;
      registerMethod('app.startApp', (Map<String, Object> args) {
        final ApplicationBundle bundle = ApplicationBundle.fromJson(args['applicationBundle']);
        final String deviceId = args['deviceId'];
        return appDomain.startApp(bundle, deviceId);
      });
      registerMethod('app.stopApp', (Map<String, Object> args) => appDomain.stopApp(ApplicationBundle.fromJson(args)));
    }
    if (buildDomain != null) {
      buildDomain._parent = this;
      registerMethod('app.build', (Map<String, Object> args) => buildDomain.buildApp(BuildInfo.fromJson(args)));
    }
   }

  FileSystem fileSystem = const LocalFileSystem();
  ProcessManager processManager = const LocalProcessManager();
  Platform platform = const LocalPlatform();

  final Map<String, DomainHandler> _domainHandlers = <String, DomainHandler>{};

  @protected
  void registerMethod(String name, DomainHandler domainHandler) {
    _domainHandlers[name] = domainHandler;
  }

  /// This method is temporarily public while the API is developed.
  Future<Response> handleMessage(Request request) async {
    Response response;
    final DomainHandler handler = _domainHandlers[request.method];
    if (handler != null) {
      try {
        final Serializable body = await handler(request.arguments);
        // Forward compatibility with isolates: force data to be json serializable.
        assert(() {
          // Should throw an exception if code is not json serializable.
          json.encode(body);
          return true;
        }());
        response = Response(request.id, body.toJson());
      } catch (err, stackTrace) {
        response = Response(request.id, null, <String, Object>{
          'error': err.toString(),
          'stackTrace': stackTrace.toString(),
        });
      }
    } else {
      response = Response(request.id, null, <String, Object>{
        'error': 'No method named ${request.method} defined.'
      });
    }
    return response;
  }

  /// The name of this extension.
  ///
  /// This is currently only used for debugging purposes.
  String get name;

  /// The [DoctorDomain] for this extension, or null if not supported.
  DoctorDomain get doctorDomain => null;

  /// The [DeviceDomain] for this extension, or null if not supported.
  DeviceDomain get deviceDomain => null;

  /// The [AppDomain] for this extension, or null if not supported.
  AppDomain get appDomain => null;

  /// The [BuildDomain] for this extension, or null if not supported.
  BuildDomain get buildDomain => null;
}

/// A building-block of tool functionality.
///
/// This class must be extended in order to function correctly.
abstract class Domain {
  // Initialized after the domain is created.
  ToolExtension _parent;

  /// An injectable interface for filesystem interaction.
  ///
  /// Extensions should use this instead of `dart:io` directly to improve
  /// testability.
  FileSystem get fileSystem => _parent.fileSystem;

  /// An injectable manager for launching and running processes.
  ///
  /// Extensions should use this instead of `dart:io` directly to improve
  /// testability.
  ProcessManager get processManager => _parent.processManager;

  /// An injectable manager for interacting with the current platform.
  ///
  /// Extensions should use this instead of `dart:io` directly to improve
  /// testability.
  Platform get platform => _parent.platform;
}
