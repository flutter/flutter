#include <impeller/color.glsl>
#include <impeller/types.glsl>

uniform FragInfo {
  vec4 color;
  float aa_pixels;
  float half_stroke_width;
}
frag_info;

in float v_sdf;
out vec4 frag_color;

void main() {
  float dist_to_edge = v_sdf - frag_info.half_stroke_width;

  // Simple smoothstep anti-aliasing
  float fade_size = frag_info.aa_pixels * 0.5;
  float alpha = 1.0 - smoothstep(-fade_size, fade_size, dist_to_edge);

  vec4 final_color = vec4(frag_info.color.rgb, frag_info.color.a * alpha);
  frag_color = IPPremultiply(final_color);
}
