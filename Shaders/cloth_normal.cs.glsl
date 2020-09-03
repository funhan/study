#version 430

layout(local_size_x = 32, local_size_y = 8) in;

layout(std430, binding = 0) buffer PosIn {
	vec4 pos_in[];
};

layout(std430, binding = 4) buffer NormOut {
	vec4 norm_out[];
};

void main() {	
	uvec3 nParticles = gl_NumWorkGroups * gl_WorkGroupSize;
	uint idx = gl_GlobalInvocationID.y * nParticles.x + gl_GlobalInvocationID.x;
	
	vec3 p = vec3(pos_in[idx]);
	vec3 n = vec3(0.0f, 0.0f, 0.0f);
	vec3 a, b, c;

	if (gl_GlobalInvocationID.y < nParticles.y - 1) {
		c = pos_in[idx + nParticles.x].xyz - p;
		if (gl_GlobalInvocationID.x < nParticles.x - 1) {
			a = pos_in[idx + 1].xyz - p;
			b = pos_in[idx + nParticles.x + 1].xyz - p;
			n += cross(a, b);
			n += cross(b, c);
		}
		if (gl_GlobalInvocationID.x > 0) {
			a = c;
			b = pos_in[idx + nParticles.x - 1].xyz - p;
			c = pos_in[idx - 1].xyz - p;
			n += cross(a, b);
			n += cross(b, c);
		}
	}

	if (gl_GlobalInvocationID.y > 0) {
		c = pos_in[idx - nParticles.x].xyz - p;
		if (gl_GlobalInvocationID.x > 0) {
			a = pos_in[idx - 1].xyz - p;
			b = pos_in[idx - nParticles.x - 1].xyz - p;
			n += cross(a, b);
			n += cross(b, c);
		}
		if (gl_GlobalInvocationID.x < nParticles.x - 1) {
			a = c;
			b = pos_in[idx - nParticles.x + 1].xyz - p;
			c = pos_in[idx + 1].xyz - p;
			n += cross(a, b);
			n += cross(b, c);
		}
	}

	norm_out[idx] = vec4(normalize(n), 0.0);
}