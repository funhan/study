#version 430

struct LIGHT {
	vec4 position; // assume point or direction in EC in this example shader
	vec4 ambient_color, diffuse_color, specular_color;
	vec4 light_attenuation_factors; // compute this effect only if .w != 0.0f
	vec3 spot_direction;
	float spot_exponent;
	float spot_cutoff_angle;
	bool light_on;
	bool shadow_on;
};

// uniform
layout(binding = 0) uniform sampler2D u_PositionTex;
layout(binding = 1) uniform sampler2D u_NormalTex;
layout(binding = 2) uniform sampler2D u_DiffuseTex;
layout(binding = 3) uniform sampler2D u_AmbientTex;
layout(binding = 4) uniform sampler2D u_EmissiveTex;
layout(binding = 5) uniform sampler2D u_SpecularTex;
layout(binding = 7) uniform sampler2D u_AoTex;

#define MAX_NUMBER_OF_LIGHTS 4

uniform vec4 u_global_ambient_color;
uniform LIGHT u_light[MAX_NUMBER_OF_LIGHTS];

uniform bool u_ssao_on = true;
uniform int u_num_of_light;

uniform sampler2DShadow u_shadow_texture[MAX_NUMBER_OF_LIGHTS];
uniform mat4 u_shadow_matrix[MAX_NUMBER_OF_LIGHTS];

const float zero_f = 0.0f;
const float one_f = 1.0f;

// input
in vec2 v_tex_coord;

// output
layout(location = 0) out vec4 final_color;

vec4 lighting_equation_textured(
	in vec3 P_EC, in vec3 N_EC, in vec4 base_color, in vec4 ambient_color, 
	in vec4 emissive_color, in vec4 specular_color, in float ambient_occlusion);

void main(void) {
	vec3 position_EC = texture(u_PositionTex, v_tex_coord).xyz;
	vec3 normal_EC = texture(u_NormalTex, v_tex_coord).xyz;
	vec4 ambient_color = vec4(texture(u_AmbientTex, v_tex_coord).xyz, 1.0f);
	vec4 emissive_color = vec4(texture(u_EmissiveTex, v_tex_coord).xyz, 1.0f);
	vec4 specular_color = texture(u_SpecularTex, v_tex_coord); // .w = specular_exponent
	vec4 base_color = texture(u_DiffuseTex, v_tex_coord); 
	
	float ambient_occlusion;

	if (u_ssao_on)
		ambient_occlusion = texture(u_AoTex, v_tex_coord).r;
	else
		ambient_occlusion = 1.0f;

	final_color = 
		lighting_equation_textured(
			position_EC, normal_EC, base_color,
			ambient_color, emissive_color, specular_color, 
			ambient_occlusion);
}

vec4 lighting_equation_textured(
	in vec3 P_EC, in vec3 N_EC, in vec4 base_color, in vec4 ambient_color, 
	in vec4 emissive_color, in vec4 specular_color, in float ambient_occlusion)
{
	vec4 color_sum;
	float local_scale_factor, tmp_float, shadow_factor;
	vec3 L_EC;
	vec4 v_shadow_coord[MAX_NUMBER_OF_LIGHTS];

	color_sum = emissive_color + ambient_occlusion * u_global_ambient_color * base_color;

	for (int i = 0; i < u_num_of_light; ++i) {
		if (!u_light[i].light_on) continue;

		if (u_light[i].shadow_on) {
			v_shadow_coord[i] = u_shadow_matrix[i] * vec4(P_EC, 1.0f);
			shadow_factor = textureProj(u_shadow_texture[i], v_shadow_coord[i]);
		}
		else
			shadow_factor = 1.0f;

		local_scale_factor = one_f;
		if (u_light[i].position.w != zero_f) { // point light source
			L_EC = u_light[i].position.xyz - P_EC.xyz;

			if (u_light[i].light_attenuation_factors.w != zero_f) {
				vec4 tmp_vec4;

				tmp_vec4.x = one_f;
				tmp_vec4.z = dot(L_EC, L_EC);
				tmp_vec4.y = sqrt(tmp_vec4.z);
				tmp_vec4.w = zero_f;
				local_scale_factor = one_f / dot(tmp_vec4, u_light[i].light_attenuation_factors);
			}

			L_EC = normalize(L_EC);

			if (u_light[i].spot_cutoff_angle < 180.0f) { // [0.0f, 90.0f] or 180.0f
				float spot_cutoff_angle = clamp(u_light[i].spot_cutoff_angle, zero_f, 90.0f);
				vec3 spot_dir = normalize(u_light[i].spot_direction);

				tmp_float = dot(-L_EC, spot_dir);
				if (tmp_float >= cos(radians(u_light[i].spot_cutoff_angle))) {
					tmp_float = pow(tmp_float, u_light[i].spot_exponent);
				}
				else
					tmp_float = zero_f;
				local_scale_factor *= tmp_float;
			}
		}
		else {  // directional light source
			L_EC = normalize(u_light[i].position.xyz);
		}

		if (local_scale_factor > zero_f) {
			vec4 local_color_sum = u_light[i].ambient_color * ambient_color * ambient_occlusion;

			if (shadow_factor > zero_f) {
				tmp_float = dot(N_EC, L_EC);
				if (tmp_float > zero_f) {
					local_color_sum += u_light[i].diffuse_color*base_color*tmp_float;

					vec3 H_EC = normalize(L_EC - normalize(P_EC));
					tmp_float = dot(N_EC, H_EC);
					if (tmp_float > zero_f) {
						local_color_sum += u_light[i].specular_color *
							vec4(specular_color.x, specular_color.y, specular_color.z, 1.0f) * 
							pow(tmp_float, specular_color.w);
					}
				}
			}

			color_sum += local_scale_factor * local_color_sum;
		}
	}
	return color_sum;
}