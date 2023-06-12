// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Library to create and parse source maps.
///
/// Create a source map using [SourceMapBuilder]. For example:
///     var json = (new SourceMapBuilder()
///         ..add(inputSpan1, outputSpan1)
///         ..add(inputSpan2, outputSpan2)
///         ..add(inputSpan3, outputSpan3)
///         .toJson(outputFile);
///
/// Use the source_span package's [SourceSpan] and [SourceFile] classes to
/// specify span locations.
///
/// Parse a source map using [parse], and call `spanFor` on the returned mapping
/// object. For example:
///     var mapping = parse(json);
///     mapping.spanFor(outputSpan1.line, outputSpan1.column)
library source_maps;

import 'package:source_span/source_span.dart';

import 'parser.dart';
import 'builder.dart';

export 'builder.dart';
export 'parser.dart';
export 'printer.dart';
export 'refactor.dart';
export 'src/source_map_span.dart';
