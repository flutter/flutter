#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform sampler2D uTexture;

// multiplier to apply to scale effect.
uniform float uMaxStretchIntensity;

// Normalized overscroll amount in the horizontal direction
uniform float uOverscrollX;

// Normalized overscroll amount in the vertical direction
uniform float uOverscrollY;

// uInterpolationStrength is the intensity of the interpolation.
uniform float uInterpolationStrength;

float easeIn(float t, float d) {
    return t * d;
}

float computeOverscrollStart(
    float inPos,
    float overscroll,
    float uStretchAffectedDist,
    float uInverseStretchAffectedDist,
    float distanceStretched,
    float interpolationStrength
) {
    float offsetPos = uStretchAffectedDist - inPos;
    float posBasedVariation = mix(
            1.0 ,easeIn(offsetPos, uInverseStretchAffectedDist), interpolationStrength);
    float stretchIntensity = overscroll * posBasedVariation;
    return distanceStretched - (offsetPos / (1.0 + stretchIntensity));
}

float computeOverscrollEnd(
    float inPos,
    float overscroll,
    float reverseStretchDist,
    float uStretchAffectedDist,
    float uInverseStretchAffectedDist,
    float distanceStretched,
    float interpolationStrength,
    float viewportDimension
) {
    float offsetPos = inPos - reverseStretchDist;
    float posBasedVariation = mix(
            1.0 ,easeIn(offsetPos, uInverseStretchAffectedDist), interpolationStrength);
    float stretchIntensity = (-overscroll) * posBasedVariation;
    return viewportDimension - (distanceStretched - (offsetPos / (1.0 + stretchIntensity)));
}

float computeOverscroll(
    float inPos,
    float overscroll,
    float uStretchAffectedDist,
    float uInverseStretchAffectedDist,
    float distanceStretched,
    float distanceDiff,
    float interpolationStrength,
    float viewportDimension
) {
  if (overscroll > 0.0) {
    if (inPos <= uStretchAffectedDist) {
        return computeOverscrollStart(
          inPos,
          overscroll,
          uStretchAffectedDist,
          uInverseStretchAffectedDist,
          distanceStretched,
          interpolationStrength
        );
    } else {
        return distanceDiff + inPos;
    }
  } else if (overscroll < 0.0) {
    float stretchAffectedDist_calc = viewportDimension - uStretchAffectedDist;
    if (inPos >= stretchAffectedDist_calc) {
        return computeOverscrollEnd(
          inPos,
          overscroll,
          stretchAffectedDist_calc,
          uStretchAffectedDist,
          uInverseStretchAffectedDist,
          distanceStretched,
          interpolationStrength,
          viewportDimension
        );
    } else {
        return -distanceDiff + inPos;
    }
  } else {
    return inPos;
  }
}

out vec4 fragColor;

void main() {
    vec2 texCoord = FlutterFragCoord().xy / uSize;
    float inU_norm = texCoord.x;
    float inV_norm = texCoord.y;

    float outU_norm;
    float outV_norm;

    float norm_stretch_affected_dist_x = 1.0;
    float norm_stretch_affected_dist_y = 1.0;

    float norm_inverse_stretch_affected_dist_x = 1.0 / norm_stretch_affected_dist_x;
    float norm_inverse_stretch_affected_dist_y = 1.0 / norm_stretch_affected_dist_y;

    float norm_distance_stretched_x = 1.0 / (1.0 + abs(uOverscrollX));
    float norm_distance_stretched_y = 1.0 / (1.0 + abs(uOverscrollY));

    float norm_dist_diff_x = norm_distance_stretched_x - 1.0;
    float norm_dist_diff_y = norm_distance_stretched_y - 1.0;

    float norm_viewport_width = 1.0;
    float norm_viewport_height = 1.0;

    float current_uScrollX = 0.0;
    float current_uScrollY = 0.0;

    inU_norm += current_uScrollX;
    inV_norm += current_uScrollY;

    outU_norm = computeOverscroll(
        inU_norm,
        uOverscrollX,
        norm_stretch_affected_dist_x,
        norm_inverse_stretch_affected_dist_x,
        norm_distance_stretched_x,
        norm_dist_diff_x,
        uInterpolationStrength,
        norm_viewport_width
    );

    outV_norm = computeOverscroll(
        inV_norm,
        uOverscrollY,
        norm_stretch_affected_dist_y,
        norm_inverse_stretch_affected_dist_y,
        norm_distance_stretched_y,
        norm_dist_diff_y,
        uInterpolationStrength,
        norm_viewport_height
    );

    texCoord.x = outU_norm;
    texCoord.y = outV_norm;

    fragColor = texture(uTexture, texCoord);
}