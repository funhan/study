#version 430

uniform mat4 u_ModelMatrix;

layout(location = 0) in vec3 a_position;

out vec2 v_tex_coord;

void main(void) {
	gl_Position = u_ModelMatrix * vec4(a_position, 1.0f);
}