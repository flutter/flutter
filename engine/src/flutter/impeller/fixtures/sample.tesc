layout(vertices = 4) out;

void main() {
   gl_out[gl_InvocationID].gl_Position = gl_in[gl_InvocationID].gl_Position;
}
