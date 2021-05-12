
#include "types.h"

uniform Uniforms {
  Hello myHello;
  vec4 hi;
  Hello goodbyeHello;
};

uniform sampler2D textureSampler;

layout(location = 3) in vec2 inTextureCoord;

layout(location = 4) out vec4 outColor;

void main() {
  outColor = texture(textureSampler, inTextureCoord * goodbyeHello.yet_more_stuff);
}
