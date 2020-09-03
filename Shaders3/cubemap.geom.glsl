#version 430

layout(triangles, invocations = 6) in;
layout(triangle_strip, max_vertices = 3) out;

uniform mat4 u_vp_right, u_vp_left;
uniform mat4 u_vp_top, u_vp_bottom;
uniform mat4 u_vp_front, u_vp_back;

uniform mat4 u_ModelMatrix;

in vec3 v_position_WC[];
in vec3 v_normal_WC[];
in vec2 v_tex_coord[];

out vec3 g_position_WC;
out vec3 g_normal_WC;
out vec2 g_tex_coord;

void main(void) {
	mat4 tmp_vp;
	if (gl_InvocationID == 0) tmp_vp = u_vp_right;
	else if (gl_InvocationID == 1) tmp_vp = u_vp_left;
	else if (gl_InvocationID == 2) tmp_vp = u_vp_top;
	else if (gl_InvocationID == 3) tmp_vp = u_vp_bottom;
	else if (gl_InvocationID == 4) tmp_vp = u_vp_back;
	else if (gl_InvocationID == 5) tmp_vp = u_vp_front;

	for (int i = 0; i < gl_in.length(); ++i) {
		gl_Layer		= gl_InvocationID;
		g_position_WC	= v_position_WC[i];
		g_normal_WC		= v_normal_WC[i];
		g_tex_coord		= v_tex_coord[i];
		gl_Position		= tmp_vp * u_ModelMatrix * gl_in[i].gl_Position;

		EmitVertex();
	}
	EndPrimitive();
}
