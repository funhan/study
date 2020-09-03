#version 430

#define MAX_NUMBER_OF_LIGHTS 4

uniform int u_num_of_light;

uniform mat4 u_ModelMatrix;
uniform mat4 u_ModelViewProjectionMatrix;

uniform mat4 u_shadow_matrix[MAX_NUMBER_OF_LIGHTS];

layout(location = 0) in vec3 a_position;
layout(location = 1) in vec3 a_normal;
layout(location = 2) in vec2 a_tex_coord;

out vec3 v_position_WC;
out vec3 v_normal_WC;
out vec2 v_tex_coord;
out vec4 v_shadow_coord[MAX_NUMBER_OF_LIGHTS];

void main(void) {
	v_position_WC = vec3(u_ModelMatrix * vec4(a_position, 1.0f));
	v_normal_WC = normalize(mat3(u_ModelMatrix) * a_normal);
	//v_normal_WC = normalize(transpose(inverse(mat3(u_ModelMatrix))) * a_normal); // 강체변환 역행렬 = 전치행렬
	v_tex_coord = a_tex_coord;

	for (int i = 0; i < u_num_of_light; ++i)
		v_shadow_coord[i] = u_shadow_matrix[i] * vec4(a_position, 1.0f);

	gl_Position = u_ModelViewProjectionMatrix * vec4(a_position, 1.0f);
}