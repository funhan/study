#version 430

// uniform
uniform samplerCube u_base_texture;

in vec3 v_position;

layout(location = 0) out vec4 final_color;

void main(void) {
	final_color = texture(u_base_texture, v_position);
	//final_color = vec4(v_position, 1.0f);
}
