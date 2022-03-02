#version 450

layout (location = 0) out vec4 oColor;

layout (location = 0) uniform float a;

void main() {
  oColor = vec4(0);
  for (float i = 0; i < 10.0; i++) {
    oColor.r += a;
  }
  oColor.a = 1.0;
}
