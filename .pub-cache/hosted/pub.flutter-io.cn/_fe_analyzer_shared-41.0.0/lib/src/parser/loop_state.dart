// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _fe_analyzer_shared.parser.loop_state;

enum LoopState {
  OutsideLoop,
  InsideSwitch, // `break` statement allowed
  InsideLoop, // `break` and `continue` statements allowed
}
