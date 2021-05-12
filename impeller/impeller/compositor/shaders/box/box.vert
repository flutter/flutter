uniform UniformBufferObject {
  mat4 model;
  mat4 view;
  mat4 projection;
} ubo;

in vec3 inPosition;

void main() {
  gl_Position =  ubo.projection * ubo.view * ubo.model * vec4(inPosition, 1.0);
}
