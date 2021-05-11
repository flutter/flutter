
#include "types.h"

uniform Uniforms {
  Hello myHello;
  vec4 hi;
  Hello goodbyeHello;
};

uniform sampler2D textureSampler;

in vec2 inTextureCoord;

out vec4 outColor;

void main() {
  outColor = texture(textureSampler, inTextureCoord * myHello.more_stuff);
}
