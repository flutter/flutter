// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// =============================================================================
// 1. Native Support Channel
// =============================================================================

/// The MethodChannel name used for query and control of native platform capabilities.
const nativeSupportChannelName = 'com.example.android_hardware_smoke_test/native_support';

/// The MethodChannel method name used to query the active graphics rendering backend.
const methodImpellerBackend = 'impeller_backend';

// =============================================================================
// 2. Test Message Channel
// =============================================================================

/// The BasicMessageChannel name used for sending orchestration commands and
/// test scenarios between the host-side test driver and the app.
const testChannelName = 'com.example.android_hardware_smoke_test/test_channel';

// -----------------------------------------------------------------------------
// Payload Dictionary Keys (JSON Keys)
// -----------------------------------------------------------------------------

/// The JSON key used to specify an orchestration command.
///
/// **Usage:** Optional. When present, the payload is treated as an out-of-band
/// command (e.g., [commandCompareGolden]) rather than a standard test scenario.
const keyCommand = 'command';

/// The JSON key used to specify the name of the test scenario to execute.
///
/// **Usage:** Required for standard test scenario rendering requests.
const keyTestName = 'testName';

/// The JSON key containing the base64-encoded screenshot image bytes.
///
/// **Usage:** Included in response/reply payloads when returning captured image
/// data to the host.
const keyImageBytes = 'imageBytes';

/// The JSON key used to indicate whether golden comparison should be executed
/// on the device itself (app-side) or deferred to the host runner.
///
/// **Usage:** Optional. Defaults to `true`.
const keyPerformAppSideGoldenCompare = 'performAppSideGoldenCompare';

/// The JSON key indicating whether a screenshot capture should occur.
///
/// **Usage:** Optional. Defaults to `true`. Widget tests set this to `false` to
/// avoid asynchronous pixel decoding deadlocks.
const keyCaptureScreenshot = 'captureScreenshot';

/// The JSON key for the golden variant name returned by the query.
///
/// **Usage:** Included in response payloads for [commandGetGoldenVariant].
const keyGoldenVariant = 'goldenVariant';

/// The JSON key for the status or failure message returned in response payloads.
///
/// **Usage:** Included in all handler response payloads.
const keyMessage = 'message';

/// The JSON key containing the reason why a test scenario was skipped.
///
/// **Usage:** Included in response payloads when a scenario is skipped (e.g.,
/// due to lack of HCPP support).
const keyReason = 'reason';

/// Payload JSON key identifying the physical x-coordinate of the platform view on the screen.
const keyX = 'x';

/// Payload JSON key identifying the physical y-coordinate of the platform view on the screen.
const keyY = 'y';

/// Payload JSON key identifying the physical width of the platform view on the screen.
const keyWidth = 'width';

/// Payload JSON key identifying the physical height of the platform view on the screen.
const keyHeight = 'height';

// -----------------------------------------------------------------------------
// Command Payload Values (Values for [keyCommand])
// -----------------------------------------------------------------------------

/// The command value queried by the host to discover the active graphics rendering backend.
const commandGetGoldenVariant = 'get_golden_variant';

/// The command value triggering an on-device golden pixel-exact comparison of
/// external compositor screenshots.
const commandCompareGolden = 'compare_golden';

// -----------------------------------------------------------------------------
// Test Scenario Names (Values for [keyTestName])
// -----------------------------------------------------------------------------

/// Scenario name for rendering a simple solid blue rectangle.
const kBlueRectangleTest = 'blueRectangleTest';

/// Scenario name for rendering a blue triangle using a path drawing paint.
const kTrianglePathTest = 'trianglePathTest';

/// Scenario name for rendering standard text with an emoji on the canvas.
const kTextTest = 'textTest';

/// Scenario name for rendering loaded image textures in memory.
const kImageTest = 'imageTest';

/// Scenario name for rendering overlapped colored circles utilizing a difference blend mode.
const kAdvancedBlendTest = 'advancedBlendTest';

/// Scenario name for rendering a centered BackdropFilter Gaussian blur layer.
const kBackdropFilterBlurTest = 'backdropFilterBlurTest';

/// The prefix shared by all platform view scenario names.
const platformViewPrefix = 'platformView';

/// Scenario name for embedding a native platform view using Texture Layer Hybrid Composition.
const kPlatformViewTextureLayerTest = '${platformViewPrefix}TextureLayerTest';

/// Scenario name for embedding a native platform view using Hybrid Composition.
const kPlatformViewHybridCompositionTest = '${platformViewPrefix}HybridCompositionTest';

/// Scenario name for embedding a native platform view using Hybrid Composition++.
const kPlatformViewHybridCompositionPlusPlusTest =
    '${platformViewPrefix}HybridCompositionPlusPlusTest';
