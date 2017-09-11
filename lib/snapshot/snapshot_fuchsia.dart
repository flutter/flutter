// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// These libraries are required. Only the core snapshot knows how to resolve
// them.
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:core';
import 'dart:developer';
import 'dart:fuchsia';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:mozart.internal';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:zircon';

// These libraries are optional. They are included in the core snapshot and
// partially compiled to avoid repeating them in each application and improve
// startup time.
import 'package:lib.app.dart/app.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.fidl.dart/bindings.dart';
