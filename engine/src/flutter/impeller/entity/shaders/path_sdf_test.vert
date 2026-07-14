#include <impeller/types.glsl>

uniform FrameInfo {
  mat4 mvp;
}
frame_info;

in vec2 position;
in float sdf;

out float v_sdf;

void main() {
  gl_Position = frame_info.mvp * vec4(position, 0.0, 1.0);
  v_sdf = sdf;
}
