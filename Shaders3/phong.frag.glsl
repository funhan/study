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

struct MATERIAL {
	vec3 ambient_color;
	vec3 diffuse_color;
	vec3 specular_color;
	vec3 emissive_color;
	float specular_exponent;
};

#define MAX_NUMBER_OF_LIGHTS 4

// uniform
uniform vec4 u_global_ambient_color;
uniform LIGHT u_light[MAX_NUMBER_OF_LIGHTS];
uniform MATERIAL u_material;

uniform bool u_exist_texture;
uniform bool u_texture_on = false;

uniform int u_cubemap_flag;
uniform int u_reflect_flag;

uniform int u_num_of_light;
uniform vec3 u_camera_position;

uniform sampler2D u_base_texture;
//uniform samplerCube u_cubemap_texture;

layout(binding = 0) uniform samplerCube u_skybox_texture;
layout(binding = 1) uniform samplerCube u_cubemap_texture;
layout(binding = 2) uniform samplerCube u_check_texture;

// const
const float zero_f = 0.0f;
const float one_f = 1.0f;

// input
in vec3 v_position_WC;
in vec3 v_normal_WC;
in vec2 v_tex_coord;

// output
layout(location = 0) out vec4 final_color;

vec4 lighting_equation_textured(in vec4 base_color);

void main(void) {
	if (u_cubemap_flag == 1) {
		vec3 I, R;
		if (u_reflect_flag == 0) {
			I = normalize(v_position_WC - u_camera_position);
			R = reflect(I, normalize(v_normal_WC));
			final_color = vec4(texture(u_check_texture, R).rgb, 1.0f);
			if (final_color.x != 0.0f)
				final_color = vec4(texture(u_cubemap_texture, R).rgb, 1.0f);
			else
				final_color = vec4(texture(u_skybox_texture, vec3(R.x, -R.y, R.z)).rgb, 1.0f);
		}
		else {
			float ratio = 1.00 / 1.52;
			I = normalize(v_position_WC - u_camera_position);
			R = refract(I, normalize(v_normal_WC), ratio);
			final_color = vec4(texture(u_check_texture, R).rgb, 1.0f);
			if (final_color.x != 0.0f)
				final_color = vec4(texture(u_cubemap_texture, R).rgb, 1.0f);
			else
				final_color = vec4(texture(u_skybox_texture, vec3(R.x, -R.y, R.z)).rgb, 1.0f);
		}
	}

	else { // just phong shading
		vec4 base_color;
		if (u_texture_on && u_exist_texture)
			base_color = texture(u_base_texture, v_tex_coord);
		else
			base_color = vec4(u_material.diffuse_color, 1.0f);

		final_color = lighting_equation_textured(base_color);
	}
}

vec4 lighting_equation_textured(in vec4 base_color) {
	vec4 color_sum;
	float local_scale_factor, tmp_float;
	vec3 L_WC;

	color_sum = vec4(u_material.emissive_color, 1.0f) + u_global_ambient_color * base_color;

	for (int i = 0; i < u_num_of_light; ++i) {
		if (!u_light[i].light_on) continue;

		local_scale_factor = one_f;
		if (u_light[i].position.w != zero_f) { // point light source
			L_WC = u_light[i].position.xyz - v_position_WC.xyz;

			if (u_light[i].light_attenuation_factors.w != zero_f) {
				vec4 tmp_vec4;

				tmp_vec4.x = one_f;
				tmp_vec4.z = dot(L_WC, L_WC);
				tmp_vec4.y = sqrt(tmp_vec4.z);
				tmp_vec4.w = zero_f;
				local_scale_factor = one_f / dot(tmp_vec4, u_light[i].light_attenuation_factors);
			}

			L_WC = normalize(L_WC);

			if (u_light[i].spot_cutoff_angle < 180.0f) { // [0.0f, 90.0f] or 180.0f // spot light
				float spot_cutoff_angle = clamp(u_light[i].spot_cutoff_angle, zero_f, 90.0f);
				vec3 spot_dir = normalize(u_light[i].spot_direction.xyz);

				tmp_float = dot(-L_WC, spot_dir);
				if (tmp_float >= cos(radians(u_light[i].spot_cutoff_angle))) {
					tmp_float = pow(tmp_float, u_light[i].spot_exponent);
				}
				else
					tmp_float = zero_f;
				local_scale_factor *= tmp_float;
			}
		}
		else {  // directional light source
			L_WC = normalize(u_light[i].position.xyz);
		}

		if (local_scale_factor > zero_f) {
			vec4 local_color_sum = u_light[i].ambient_color * vec4(u_material.ambient_color, 1.0f);
			
			tmp_float = dot(v_normal_WC, L_WC);
			if (tmp_float > zero_f) {
				local_color_sum += u_light[i].diffuse_color * base_color * tmp_float;

				vec3 H_WC = normalize(L_WC + normalize(u_camera_position - v_position_WC)); //halfway vector
				tmp_float = dot(v_normal_WC, H_WC);
				if (tmp_float > zero_f) {
					local_color_sum += u_light[i].specular_color *
						vec4(u_material.specular_color, 1.0f) *
						pow(tmp_float, u_material.specular_exponent);
				}
			}			
			color_sum += local_scale_factor * local_color_sum;
		}
	}
	return color_sum;
}