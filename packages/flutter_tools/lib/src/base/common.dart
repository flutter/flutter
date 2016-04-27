// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

const int defaultObservatoryPort = 8100;
const int defaultDiagnosticPort  = 8101;
const int defaultDrivePort       = 8183;

// Names of some of the Timeline events we care about
const String flutterEngineMainEnterEventName = 'FlutterEngineMainEnter';
const String frameworkInitEventName = 'Framework initialization';
const String firstUsefulFrameEventName = 'Widgets completed first useful frame';
