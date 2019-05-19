#version 300 es

precision highp float;

in vec2 vert_position;

out vec2 norm_coords;

void main() {
  norm_coords = vert_position;
  gl_Position = vec4(vert_position, 0.0, 1.0);
}
