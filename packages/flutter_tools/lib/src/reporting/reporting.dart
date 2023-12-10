// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library reporting;

import 'dart:async';

import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';
import 'package:usage/usage_io.dart';

import '../base/error_handling_io.dart';
import '../base/time.dart';
import '../build_info.dart';
import '../dart/language_version.dart';
import '../doctor_validator.dart';
import '../features.dart';
import '../globals.dart' as globals;
import '../version.dart';
import 'first_run.dart';

part 'disabled_usage.dart';
part 'events.dart';
part 'usage.dart';
part 'custom_dimensions.dart';
