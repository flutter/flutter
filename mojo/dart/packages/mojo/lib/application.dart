// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library application;

import 'dart:async';
import 'dart:collection';

import 'package:mojo/bindings.dart' as bindings;
import 'package:mojo/core.dart' as core;
import 'package:mojo/mojo/application.mojom.dart' as application_mojom;
import 'package:mojo/mojo/bindings/types/service_describer.mojom.dart'
    as service_describer;
import 'package:mojo/mojo/service_provider.mojom.dart';
import 'package:mojo/mojo/shell.mojom.dart' as shell_mojom;

part 'src/application.dart';
part 'src/application_connection.dart';
part 'src/service_describer.dart';
