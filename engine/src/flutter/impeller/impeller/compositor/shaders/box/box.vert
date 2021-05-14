#include "types.h"

uniform UniformBufferObject {
  Uniforms uniforms;
} ubo;

in vec3 inPosition;

in vec4 inAnotherPosition;

layout(location = 3) in float stuff;

out float outStuff;

void main() {
  gl_Position =  ubo.uniforms.projection * ubo.uniforms.view * ubo.uniforms.model * vec4(inPosition, 1.0) * inAnotherPosition;
  outStuff = stuff;
}

