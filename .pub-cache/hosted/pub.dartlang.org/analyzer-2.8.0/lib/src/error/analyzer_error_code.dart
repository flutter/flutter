// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';

/// A superclass for error codes that can have a url associated with them.
abstract class AnalyzerErrorCode extends ErrorCode {
  /// Initialize a newly created error code.
  const AnalyzerErrorCode({
    String? correctionMessage,
    bool hasPublishedDocs = false,
    bool isUnresolvedIdentifier = false,
    required String name,
    required String problemMessage,
    required String uniqueName,
  }) : super(
          correctionMessage: correctionMessage,
          hasPublishedDocs: hasPublishedDocs,
          isUnresolvedIdentifier: isUnresolvedIdentifier,
          name: name,
          problemMessage: problemMessage,
          uniqueName: uniqueName,
        );
}
