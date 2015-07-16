// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.ui.interpolators;

import android.view.animation.Interpolator;

/**
 * A pre-baked bezier-curved interpolator for quantum-paper transitions.
 * TODO(dtrainor): Move to the API Compatability version iff that supports the curves we need and
 * once we move to that SDK.
 */
public class BakedBezierInterpolator implements Interpolator {
    /**
     * Lookup table values.
     * Generated using a Bezier curve from (0,0) to (1,1) with control points:
     * P0 (0.0, 0.0)
     * P1 (0.4, 0.0)
     * P2 (0.2, 1.0)
     * P3 (1.0, 1.0)
     *
     * Values sampled with x at regular intervals between 0 and 1.
     */
    private static final float[] TRANSFORM_VALUES = new float[] {
        0.0f, 0.0002f, 0.0009f, 0.0019f, 0.0036f, 0.0059f, 0.0086f, 0.0119f, 0.0157f, 0.0209f,
        0.0257f, 0.0321f, 0.0392f, 0.0469f, 0.0566f, 0.0656f, 0.0768f, 0.0887f, 0.1033f, 0.1186f,
        0.1349f, 0.1519f, 0.1696f, 0.1928f, 0.2121f, 0.237f, 0.2627f, 0.2892f, 0.3109f, 0.3386f,
        0.3667f, 0.3952f, 0.4241f, 0.4474f, 0.4766f, 0.5f, 0.5234f, 0.5468f, 0.5701f, 0.5933f,
        0.6134f, 0.6333f, 0.6531f, 0.6698f, 0.6891f, 0.7054f, 0.7214f, 0.7346f, 0.7502f, 0.763f,
        0.7756f, 0.7879f, 0.8f, 0.8107f, 0.8212f, 0.8326f, 0.8415f, 0.8503f, 0.8588f, 0.8672f,
        0.8754f, 0.8833f, 0.8911f, 0.8977f, 0.9041f, 0.9113f, 0.9165f, 0.9232f, 0.9281f, 0.9328f,
        0.9382f, 0.9434f, 0.9476f, 0.9518f, 0.9557f, 0.9596f, 0.9632f, 0.9662f, 0.9695f, 0.9722f,
        0.9753f, 0.9777f, 0.9805f, 0.9826f, 0.9847f, 0.9866f, 0.9884f, 0.9901f, 0.9917f, 0.9931f,
        0.9944f, 0.9955f, 0.9964f, 0.9973f, 0.9981f, 0.9986f, 0.9992f, 0.9995f, 0.9998f, 1.0f, 1.0f
    };

    /**
     * Lookup table values.
     * Generated using a Bezier curve from (0,0) to (1,1) with control points:
     * P0 (0.0, 0.0)
     * P1 (0.4, 0.0)
     * P2 (1.0, 1.0)
     * P3 (1.0, 1.0)
     *
     * Values sampled with x at regular intervals between 0 and 1.
     */
    private static final float[] FADE_OUT_VALUES = new float[] {
        0.0f, 0.0002f, 0.0008f, 0.0019f, 0.0032f, 0.0049f, 0.0069f, 0.0093f, 0.0119f, 0.0149f,
        0.0182f, 0.0218f, 0.0257f, 0.0299f, 0.0344f, 0.0392f, 0.0443f, 0.0496f, 0.0552f, 0.0603f,
        0.0656f, 0.0719f, 0.0785f, 0.0853f, 0.0923f, 0.0986f, 0.1051f, 0.1128f, 0.1206f, 0.1287f,
        0.1359f, 0.1433f, 0.1519f, 0.1607f, 0.1696f, 0.1776f, 0.1857f, 0.1952f, 0.2048f, 0.2145f,
        0.2232f, 0.2319f, 0.2421f, 0.2523f, 0.2627f, 0.2733f, 0.2826f, 0.2919f, 0.3027f, 0.3137f,
        0.3247f, 0.3358f, 0.3469f, 0.3582f, 0.3695f, 0.3809f, 0.3924f, 0.4039f, 0.4154f, 0.427f,
        0.4386f, 0.4503f, 0.4619f, 0.4751f, 0.4883f, 0.5f, 0.5117f, 0.5264f, 0.5381f, 0.5497f,
        0.5643f, 0.5759f, 0.5904f, 0.6033f, 0.6162f, 0.6305f, 0.6446f, 0.6587f, 0.6698f, 0.6836f,
        0.7f, 0.7134f, 0.7267f, 0.7425f, 0.7554f, 0.7706f, 0.7855f, 0.8f, 0.8143f, 0.8281f, 0.8438f,
        0.8588f, 0.8733f, 0.8892f, 0.9041f, 0.9215f, 0.9344f, 0.9518f, 0.9667f, 0.9826f, 0.9993f
    };

    /**
     * Lookup table values.
     * Generated using a Bezier curve from (0,0) to (1,1) with control points:
     * P0 (0.0, 0.0)
     * P1 (0.0, 0.0)
     * P2 (0.2, 1.0)
     * P3 (1.0, 1.0)
     *
     * Values sampled with x at regular intervals between 0 and 1.
     */
    private static final float[] FADE_IN_VALUES = new float[] {
        0.0029f, 0.043f, 0.0785f, 0.1147f, 0.1476f, 0.1742f, 0.2024f, 0.2319f, 0.2575f, 0.2786f,
        0.3055f, 0.3274f, 0.3498f, 0.3695f, 0.3895f, 0.4096f, 0.4299f, 0.4474f, 0.4649f, 0.4824f,
        0.5f, 0.5176f, 0.5322f, 0.5468f, 0.5643f, 0.5788f, 0.5918f, 0.6048f, 0.6191f, 0.6333f,
        0.6446f, 0.6573f, 0.6698f, 0.6808f, 0.6918f, 0.704f, 0.7148f, 0.7254f, 0.7346f, 0.7451f,
        0.7554f, 0.7655f, 0.7731f, 0.783f, 0.7916f, 0.8f, 0.8084f, 0.8166f, 0.8235f, 0.8315f,
        0.8393f, 0.8459f, 0.8535f, 0.8599f, 0.8672f, 0.8733f, 0.8794f, 0.8853f, 0.8911f, 0.8967f,
        0.9023f, 0.9077f, 0.9121f, 0.9173f, 0.9224f, 0.9265f, 0.9313f, 0.9352f, 0.9397f, 0.9434f,
        0.9476f, 0.9511f, 0.9544f, 0.9577f, 0.9614f, 0.9644f, 0.9673f, 0.9701f, 0.9727f, 0.9753f,
        0.9777f, 0.98f, 0.9818f, 0.9839f, 0.9859f, 0.9877f, 0.9891f, 0.9907f, 0.9922f, 0.9933f,
        0.9946f, 0.9957f, 0.9966f, 0.9974f, 0.9981f, 0.9986f, 0.9992f, 0.9995f, 0.9998f, 1.0f, 1.0f
    };

    /**
     * Lookup table values.
     * Generated using a Bezier curve from (0,0) to (1,1) with control points:
     * P0 (0.0, 0.0)
     * P1 (0.0, 0.84)
     * P2 (0.13, 0.99)
     * P3 (1.0, 1.0)
     */
    private static final float[] TRANSFORM_FOLLOW_THROUGH_VALUES = new float[] {
        0.0767f, 0.315f, 0.4173f, 0.484f, 0.5396f, 0.5801f, 0.6129f, 0.644f, 0.6687f, 0.6876f,
        0.7102f, 0.7276f, 0.7443f, 0.7583f, 0.7718f, 0.7849f, 0.7975f, 0.8079f, 0.8179f, 0.8276f,
        0.8355f, 0.8446f, 0.8519f, 0.859f, 0.8659f, 0.8726f, 0.8791f, 0.8841f, 0.8902f, 0.8949f,
        0.9001f, 0.9051f, 0.9094f, 0.9136f, 0.9177f, 0.9217f, 0.925f, 0.9283f, 0.9319f, 0.9355f,
        0.938f, 0.9413f, 0.9437f, 0.9469f, 0.9491f, 0.9517f, 0.9539f, 0.9563f, 0.9583f, 0.9603f,
        0.9622f, 0.9643f, 0.9661f, 0.9679f, 0.9693f, 0.9709f, 0.9725f, 0.974f, 0.9753f, 0.9767f,
        0.9779f, 0.9792f, 0.9803f, 0.9816f, 0.9826f, 0.9835f, 0.9845f, 0.9854f, 0.9863f, 0.9872f,
        0.988f, 0.9888f, 0.9895f, 0.9903f, 0.991f, 0.9917f, 0.9922f, 0.9928f, 0.9934f, 0.9939f,
        0.9944f, 0.9948f, 0.9953f, 0.9957f, 0.9962f, 0.9965f, 0.9969f, 0.9972f, 0.9975f, 0.9978f,
        0.9981f, 0.9984f, 0.9986f, 0.9989f, 0.9991f, 0.9992f, 0.9994f, 0.9996f, 0.9997f, 0.9999f,
        1.0f
    };

    /**
     * 0.4 to 0.2 bezier curve.  Should be used for general movement.
     */
    public static final BakedBezierInterpolator TRANSFORM_CURVE =
            new BakedBezierInterpolator(TRANSFORM_VALUES);

    /**
     * 0.4 to 1.0 bezier curve.  Should be used for fading out.
     */
    public static final BakedBezierInterpolator FADE_OUT_CURVE =
            new BakedBezierInterpolator(FADE_OUT_VALUES);

    /**
     * 0.0 to 0.2 bezier curve.  Should be used for fading in.
     */
    public static final BakedBezierInterpolator FADE_IN_CURVE =
            new BakedBezierInterpolator(FADE_IN_VALUES);

    /**
     * 0.0 to 0.13 by 0.84 to 0.99 bezier curve.  Should be used for very quick transforms.
     */
    public static final BakedBezierInterpolator TRANSFORM_FOLLOW_THROUGH_CURVE =
            new BakedBezierInterpolator(TRANSFORM_FOLLOW_THROUGH_VALUES);

    private final float[] mValues;
    private final float mStepSize;

    /**
     * Use the INSTANCE variable instead of instantiating.
     */
    private BakedBezierInterpolator(float[] values) {
        super();
        mValues = values;
        mStepSize = 1.f / (mValues.length - 1);
    }

    @Override
    public float getInterpolation(float input) {
        if (input >= 1.0f) {
            return 1.0f;
        }

        if (input <= 0f) {
            return 0f;
        }

        int position = Math.min(
                (int) (input * (mValues.length - 1)),
                mValues.length - 2);

        float quantized = position * mStepSize;
        float difference = input - quantized;
        float weight = difference / mStepSize;

        return mValues[position] + weight * (mValues[position + 1] - mValues[position]);
    }

}