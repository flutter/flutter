// // Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// // for details. All rights reserved. Use of this source code is governed by a
// // BSD-style license that can be found in the LICENSE file.
//
// import 'package:analyzer/dart/analysis/analysis_context.dart';
// import 'package:analyzer/dart/analysis/context_root.dart';
// import 'package:analyzer/dart/analysis/session.dart';
// import 'package:analyzer/file_system/file_system.dart';
// import 'package:analyzer/src/dart/analysis/driver.dart' show AnalysisDriver;
// import 'package:analyzer/src/dart/sdk/sdk.dart';
// import 'package:analyzer/src/generated/engine.dart' show AnalysisOptions;
// import 'package:analyzer/src/workspace/workspace.dart';
//
// /// [AnalysisSession] that checks at every invocation there were to changes to
// /// the underlying analysis driver since the time when the session started.
// class ConsistentAnalysisSession implements AnalysisSession {
//   final AnalysisDriver _driver;
//   final int _startModificationCount;
//
//   ConsistentAnalysisSession(this._driver)
//       : _startModificationCount = _driver.modificationCount;
// }
