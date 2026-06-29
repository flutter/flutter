// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Keys used in JSON serialization payload for VM Service communication.
const String keyCommand = 'command';
const String keyTestScenario = 'scenario';
const String keyImageBytes = 'imageBytes';
const String keyPerformAppSideGoldenCompare = 'performAppSideGoldenCompare';
const String keyCaptureScreenshot = 'captureScreenshot';
const String keyGoldenVariant = 'goldenVariant';
const String keyMessage = 'message';
const String keyReason = 'reason';
const String keyX = 'x';
const String keyY = 'y';
const String keyWidth = 'width';
const String keyHeight = 'height';

/// Commands sent from the host driver to the app-side extension.
const String commandGetGoldenVariant = 'get_golden_variant';
