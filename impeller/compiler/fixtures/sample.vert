#version 450
#extension GL_ARB_separate_shader_objects : enable

// Uniforms

layout(set = 0, binding = 0) uniform UniformBufferObject {
  mat4 mvp;
} ubo;

// In

layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec3 inNormal;
layout(location = 2) in vec2 inTextureCoords;

// Out

layout(location = 0) out vec2 outTextureCoords;

void main() {
  gl_Position = ubo.mvp * vec4(inPosition, 1.0);
  outTextureCoords = inTextureCoords;
}
