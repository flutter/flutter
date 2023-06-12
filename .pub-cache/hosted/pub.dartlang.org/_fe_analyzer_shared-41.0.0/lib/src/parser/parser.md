<!--
Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
for details. All rights reserved. Use of this source code is governed by a
BSD-style license that can be found in the LICENSE file.
-->

# Uses of peek in the parser

  * In parseType, the parser uses peekAfterIfType to tell the difference
    between `id` and `id id`.

  * In parseSwitchCase, the parser uses peekPastLabels to select between case
    labels and statement labels.

  * The parser uses isGeneralizedFunctionType in parseType.

  * The parser uses isValidMethodTypeArguments in parseSend.
