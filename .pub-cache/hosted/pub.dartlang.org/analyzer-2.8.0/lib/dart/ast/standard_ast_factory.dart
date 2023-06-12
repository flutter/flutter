// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast_factory.dart';
import 'package:analyzer/src/dart/ast/ast_factory.dart';

/// Gets an instance of [AstFactory] based on the standard AST implementation.
final AstFactory astFactory = AstFactoryImpl();
