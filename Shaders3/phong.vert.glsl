#version 430

#define MAX_NUMBER_OF_LIGHTS 4

uniform mat4 u_ModelMatrix;
uniform mat4 u_ModelViewProjectionMatrix;

layout(location = 0) in vec3 a_position;
layout(location = 1) in vec3 a_normal;
layout(location = 2) in vec2 a_tex_coord;

out vec3 v_position_WC;
out vec3 v_normal_WC;
out vec2 v_tex_coord;

void main(void) {
	v_position_WC = vec3(u_ModelMatrix * vec4(a_position, 1.0f));
	v_normal_WC = normalize(mat3(u_ModelMatrix) * a_normal);
	v_tex_coord = a_tex_coord;
	gl_Position = u_ModelViewProjectionMatrix * vec4(a_position, 1.0f);
}