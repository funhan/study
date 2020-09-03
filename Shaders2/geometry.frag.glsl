#version 430

struct MATERIAL {
	vec3 ambient_color;
	vec3 diffuse_color;
	vec3 specular_color;
	vec3 emissive_color;
	float specular_exponent;
};

uniform MATERIAL u_material;

uniform bool u_exist_texture;
uniform bool u_texture_on = false;
uniform sampler2D u_base_texture;

in vec3 v_position_EC;
in vec3 v_normal_EC;
in vec2 v_tex_coord;

layout(location = 0) out vec3 PositionData;
layout(location = 1) out vec3 NormalData;
layout(location = 2) out vec3 DiffuseData;
layout(location = 3) out vec3 AmbientData;
layout(location = 4) out vec3 EmissiveData;
layout(location = 5) out vec4 SpecularData;

void main(void) {
	PositionData = v_position_EC;
	NormalData = normalize(v_normal_EC);
	if (u_texture_on && u_exist_texture)
		DiffuseData = texture(u_base_texture, v_tex_coord).xyz;
	else
		DiffuseData = u_material.diffuse_color;

	AmbientData = u_material.ambient_color;
	EmissiveData = u_material.emissive_color;
	SpecularData = vec4(
		u_material.specular_color.x, u_material.specular_color.y, 
		u_material.specular_color.z, u_material.specular_exponent);
}