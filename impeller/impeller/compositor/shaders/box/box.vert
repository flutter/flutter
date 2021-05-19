#include "types.h"

uniform UniformBufferObject {
  Uniforms uniforms;
} ubo;

uniform sampler2D world;

in vec2 position;
in vec3 position2;
in vec4 anotherPosition;
in float stuff;

out vec4 otherStuff;

void main() {
  gl_Position =  ubo.uniforms.projection * ubo.uniforms.view * ubo.uniforms.model * vec4(position2, 1.0) * anotherPosition;
  otherStuff = texture(world, position);
}

