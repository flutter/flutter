// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

library reporting;

import 'dart:async';

import 'package:file/file.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';
import 'package:usage/usage_io.dart';

import '../base/error_handling_io.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/time.dart';
import '../build_info.dart';
import '../build_system/exceptions.dart';
import '../convert.dart';
import '../dart/language_version.dart';
import '../devfs.dart';
import '../doctor_validator.dart';
import '../features.dart';
import '../flutter_manifest.dart';
import '../flutter_project_metadata.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../runner/flutter_command.dart';
import '../version.dart';
import 'first_run.dart';

part 'crash_reporting.dart';
part 'disabled_usage.dart';
part 'events.dart';
part 'github_template.dart';
part 'usage.dart';
