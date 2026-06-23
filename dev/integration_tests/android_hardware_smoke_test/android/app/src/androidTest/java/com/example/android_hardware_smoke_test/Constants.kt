// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@file:Suppress("PackageName")

package com.example.android_hardware_smoke_test

object Constants {
    // =============================================================================
    // 1. Native Support Channel
    // =============================================================================

    const val NATIVE_SUPPORT_CHANNEL_NAME = "com.example.android_hardware_smoke_test/native_support"
    const val METHOD_IMPELLER_BACKEND = "impeller_backend"

    // =============================================================================
    // 2. Test Message Channel
    // =============================================================================

    const val TEST_CHANNEL_NAME = "com.example.android_hardware_smoke_test/test_channel"

    // -----------------------------------------------------------------------------
    // Payload Dictionary Keys (JSON Keys)
    // -----------------------------------------------------------------------------

    const val KEY_COMMAND = "command"
    const val KEY_TEST_NAME = "testName"
    const val KEY_IMAGE_BYTES = "imageBytes"
    const val KEY_PERFORM_APP_SIDE_GOLDEN_COMPARE = "performAppSideGoldenCompare"
    const val KEY_CAPTURE_SCREENSHOT = "captureScreenshot"
    const val KEY_GOLDEN_VARIANT = "goldenVariant"
    const val KEY_MESSAGE = "message"
    const val KEY_REASON = "reason"
    const val KEY_X = "x"
    const val KEY_Y = "y"
    const val KEY_WIDTH = "width"
    const val KEY_HEIGHT = "height"

    // -----------------------------------------------------------------------------
    // Command Payload Values (Values for KEY_COMMAND)
    // -----------------------------------------------------------------------------

    const val COMMAND_GET_GOLDEN_VARIANT = "get_golden_variant"
    const val COMMAND_COMPARE_GOLDEN = "compare_golden"

    // -----------------------------------------------------------------------------
    // Test Scenario Names (Values for KEY_TEST_NAME)
    // -----------------------------------------------------------------------------

    const val BLUE_RECTANGLE_TEST = "blueRectangleTest"
    const val TRIANGLE_PATH_TEST = "trianglePathTest"
    const val TEXT_TEST = "textTest"
    const val IMAGE_TEST = "imageTest"
    const val ADVANCED_BLEND_TEST = "advancedBlendTest"
    const val BACKDROP_FILTER_BLUR_TEST = "backdropFilterBlurTest"

    const val PLATFORM_VIEW_PREFIX = "platformView"
    const val PLATFORM_VIEW_TEXTURE_LAYER_TEST = "${PLATFORM_VIEW_PREFIX}TextureLayerTest"
    const val PLATFORM_VIEW_HYBRID_COMPOSITION_TEST = "${PLATFORM_VIEW_PREFIX}HybridCompositionTest"
    const val PLATFORM_VIEW_HYBRID_COMPOSITION_PLUS_PLUS_TEST =
            "${PLATFORM_VIEW_PREFIX}HybridCompositionPlusPlusTest"
}
