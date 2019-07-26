// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Core SDK libraries.
import 'dart:async';
import 'dart:core';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:fuchsia.builtin';
import 'dart:zircon';
import 'dart:fuchsia';
import 'dart:typed_data';

// If new imports are added to this list, then it is also necessary to ensure
// that the dart_deps parameter in the rule
// gen_snapshot_cc("script_runner_snapshot") in the BUILD.gn file in this
// directory is updated with any new dependencies.

import 'package:fuchsia/fuchsia.dart';
import 'package:zircon/zircon.dart';

// FIDL bindings and application libraries.
import 'package:lib.app.dart/app.dart';
import 'package:fidl/fidl.dart';

// From //sdk/fidl/fuchsia.modular
import 'package:fidl_fuchsia_modular/fidl.dart';
