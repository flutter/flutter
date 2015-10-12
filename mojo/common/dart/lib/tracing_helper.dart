// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library tracing;

import 'trace_provider_impl.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:isolate';

import 'package:mojo/application.dart';
import 'package:mojo/core.dart';
import 'package:mojo_services/tracing/tracing.mojom.dart';

// Phases indicating the nature of the event in the trace log.
// These should be in sync with definitions in
// //base/trace_event/trace_event.h
const traceEventInstant = "I";
const traceEventPhaseBegin = "B";
const traceEventPhaseEnd = "E";
const traceEventPhaseAsyncBegin = "S";
const traceEventPhaseAsyncEnd = "F";
const traceEventDuration = "X";

// TracingHelper is used by Dart code running in the Mojo shell in order
// to perform tracing.
class TracingHelper {
  TraceProviderImpl _impl;
  int _tid;
  static TracingHelper _tracing;
  // Construct an instance of TracingHelper from within your application's
  // |initialize()| method. |appName| will be used to form a thread identifier
  // for use in trace messages. If |appName| is longer than 20 characters then
  // only the last 20 characters of |appName| will be used.
  TracingHelper.fromApplication(Application app, String appName) {
    // Masked because the tid is expected to be a 32-bit int.
    _tid = [appName, Isolate.current]
            .fold(7, (hash, element) => 31 * hash + element.hashCode) &
        0x7fffffff;
    _impl = new TraceProviderImpl();
    ApplicationConnection connection = app.connectToApplication("mojo:tracing");
    connection.provideService(TraceProviderName, (e) {
      _impl.connect(e);
    });
    assert(_tracing == null);
    _tracing = this;
  }

  // Factory to return the singleton instance of the TracingHelper. The isolate
  // must have constructed the object using TracingHelper.fromApplication
  // atleast once before using this factory.
  factory TracingHelper() {
    assert(_tracing != null);
    return _tracing;
  }

  bool isActive() {
    return (_impl != null) && _impl.isActive();
  }

  // Invoke this at the beginning of a synchronous function whose
  // duration you wish to trace. Invoke |end()| on the returned object.
  FunctionTrace begin(String functionName, String categories,
      {Map<String, String> args}) {
    return _beginFunction(functionName, categories, traceEventPhaseBegin,
        args: args);
  }

  // Invoke this right before an asynchronous function whose duration
  // you wish to trace. Invoke |end()| on the returned object.
  FunctionTrace beginAsync(String functionName, String categories,
      {Map<String, String> args}) {
    return _beginFunction(functionName, categories, traceEventPhaseAsyncBegin,
        args: args);
  }

  void traceInstant(String name, String categories,
      {Map<String, String> args}) {
    _sendTraceMessage(name, categories, traceEventInstant, 0, args: args);
  }

  void traceDuration(String name, String categories, int start, int end,
      {Map<String, String> args}) {
    _sendTraceMessage(name, categories, traceEventDuration, 0,
        args: args, start: start, duration: end - start);
  }

  FunctionTrace _beginFunction(
      String functionName, String categories, String phase,
      {Map<String, String> args}) {
    assert(functionName != null);
    final trace = new _FunctionTraceImpl(
        this, isActive() ? functionName : null, categories, phase);
    _sendTraceMessage(functionName, categories, phase, trace.hashCode,
        args: args);
    return trace;
  }

  void _endFunction(
      String functionName, String categories, String phase, int traceId) {
    _sendTraceMessage(functionName, categories, phase, traceId);
  }

  void _sendTraceMessage(
      String name, String categories, String phase, int traceId,
      {Map<String, String> args, int start, int duration}) {
    if (isActive()) {
      var time = (start != null) ? start : getTimeTicksNow();
      var map = {};
      map["name"] = name;
      map["cat"] = categories;
      map["ph"] = phase;
      map["ts"] = time;
      map["pid"] = pid;
      map["tid"] = _tid;
      map["id"] = traceId;
      if (duration != null) {
        map["dur"] = duration;
      }
      if (args != null) {
        map["args"] = args;
      }
      _impl.sendTraceMessage(JSON.encode(map));
    }
  }

  // A convenience method that wraps a closure in a begin-end pair of
  // tracing calls.
  dynamic trace(String functionName, String categories, closure(),
      {Map<String, String> args}) {
    FunctionTrace ft = begin(functionName, categories, args: args);
    final returnValue = closure();
    ft.end();
    return returnValue;
  }

  // A convenience method that wraps a closure in a begin-end pair of
  // async tracing calls. The return value should either be returned or awaited.
  Future traceAsync(String functionName, String categories, Future closure(),
      {Map<String, String> args}) {
    FunctionTrace ft = beginAsync(functionName, categories, args: args);
    final Future returnValue = closure();
    returnValue.whenComplete(ft.end);
    return returnValue;
  }
}

// An instance of FunctionTrace is returned from |begin()|, |beginAsync()|.
// Invoke |end()| to end the trace from every exit point in the function you are
// tracing.
abstract class FunctionTrace {
  void end();
}

class _FunctionTraceImpl implements FunctionTrace {
  TracingHelper _tracing;
  String _functionName;
  String _categories;
  String _beginPhase;

  _FunctionTraceImpl(
      this._tracing, this._functionName, this._categories, this._beginPhase) {
    assert(_beginPhase == traceEventPhaseBegin ||
        _beginPhase == traceEventPhaseAsyncBegin);
  }

  @override
  void end() {
    if (_functionName != null) {
      if (_beginPhase == traceEventPhaseBegin) {
        _tracing._endFunction(
            _functionName, _categories, traceEventPhaseEnd, hashCode);
      } else if (_beginPhase == traceEventPhaseAsyncBegin) {
        _tracing._endFunction(
            _functionName, _categories, traceEventPhaseAsyncEnd, hashCode);
      }
    }
  }
}
