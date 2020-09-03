#version 430

layout(local_size_x = 32, local_size_y = 8) in;

uniform vec3 Gravity;
uniform float ParticleMass;
uniform float ParticleInvMass;
uniform float SpringK;
uniform float RestLengthHoriz;
uniform float RestLengthVert;
uniform float RestLengthDiag;
uniform float DeltaT;
uniform float DampingConst;

uniform int u_method_flag;

layout(std430, binding = 0) buffer PosIn {
	vec4 pos_in[];
};
layout(std430, binding = 1) buffer PosOut {
	vec4 pos_out[];
};
layout(std430, binding = 2) buffer VelIn {
	vec4 vel_in[];
};
layout(std430, binding = 3) buffer VelOut {
	vec4 vel_out[];
};

shared vec4 position_shared[(gl_WorkGroupSize.y + 2) * (gl_WorkGroupSize.x + 2) * 2];

void Euler_1st_order() 
{
	uvec3 nParticles = gl_NumWorkGroups * gl_WorkGroupSize;
	uint idx = gl_GlobalInvocationID.y * nParticles.x + gl_GlobalInvocationID.x;

	vec3 p = vec3(pos_in[idx]);
	vec3 v = vec3(vel_in[idx]);
	vec3 r;

	vec3 force = Gravity * ParticleMass;

	// Particle above
	if (gl_GlobalInvocationID.y < nParticles.y - 1) {
		r = pos_in[idx + nParticles.x].xyz - p;
		force += normalize(r) * SpringK * (length(r) - RestLengthVert);
	}
	// Below
	if (gl_GlobalInvocationID.y > 0) {
		r = pos_in[idx - nParticles.x].xyz - p;
		force += normalize(r) * SpringK * (length(r) - RestLengthVert);
	}
	// Left
	if (gl_GlobalInvocationID.x > 0) {
		r = pos_in[idx - 1].xyz - p;
		force += normalize(r) * SpringK * (length(r) - RestLengthHoriz);
	}
	// Right
	if (gl_GlobalInvocationID.x < nParticles.x - 1) {
		r = pos_in[idx + 1].xyz - p;
		force += normalize(r) * SpringK * (length(r) - RestLengthHoriz);
	}

	// Diagonals
	// Upper-left
	if (gl_GlobalInvocationID.x > 0 && gl_GlobalInvocationID.y < nParticles.y - 1) {
		r = pos_in[idx + nParticles.x - 1].xyz - p;
		force += normalize(r) * SpringK * (length(r) - RestLengthDiag);
	}
	// Upper-right
	if (gl_GlobalInvocationID.x < nParticles.x - 1 && gl_GlobalInvocationID.y < nParticles.y - 1) {
		r = pos_in[idx + nParticles.x + 1].xyz - p;
		force += normalize(r) * SpringK * (length(r) - RestLengthDiag);
	}
	// lower -left
	if (gl_GlobalInvocationID.x > 0 && gl_GlobalInvocationID.y > 0) {
		r = pos_in[idx - nParticles.x - 1].xyz - p;
		force += normalize(r) * SpringK * (length(r) - RestLengthDiag);
	}
	// lower-right
	if (gl_GlobalInvocationID.x < nParticles.x - 1 && gl_GlobalInvocationID.y > 0) {
		r = pos_in[idx - nParticles.x + 1].xyz - p;
		force += normalize(r) * SpringK * (length(r) - RestLengthDiag);
	}


	force -= DampingConst * v;

	// Apply simple Euler integrator
	vec3 a = force * ParticleInvMass;
	pos_out[idx] = vec4(p + v * DeltaT, 1.0);
	vel_out[idx] = vec4(v + a * DeltaT, 0.0);

	// Pin a few of the top verts
	if (gl_GlobalInvocationID.y == nParticles.y - 1 &&
		(gl_GlobalInvocationID.x == 0 ||
			gl_GlobalInvocationID.x == nParticles.x / 4 ||
			gl_GlobalInvocationID.x == nParticles.x * 2 / 4 ||
			gl_GlobalInvocationID.x == nParticles.x * 3 / 4 ||
			gl_GlobalInvocationID.x == nParticles.x - 1)) {
		pos_out[idx] = vec4(p, 1.0);
		vel_out[idx] = vec4(0.0, 0.0, 0.0, 0.0);
	}
}

void Euler_2nd_order()
{
	uvec3 nParticles = gl_NumWorkGroups * gl_WorkGroupSize;
	uint idx = gl_GlobalInvocationID.y * nParticles.x + gl_GlobalInvocationID.x;

	vec3 p, p2, v, force, force2, r, r2;

	p = pos_in[idx].xyz;
	v = vel_in[idx].xyz;
	p2 = p + v * DeltaT;

	// Fg 구하기
	force = Gravity * ParticleMass;					// for F(Pi) / m
	force2 = Gravity * ParticleMass;				// for F(Pi + Vi * h) / m

	// Fs 구하기
	// Particle above
	if (gl_GlobalInvocationID.y < nParticles.y - 1) {
		r = pos_in[idx + nParticles.x].xyz - p;
		force += normalize(r) * SpringK * (length(r) - RestLengthVert);
		r2 = pos_in[idx + nParticles.x].xyz + vel_in[idx + nParticles.x].xyz * DeltaT - p2;
		force2 += normalize(r2) * SpringK * (length(r2) - RestLengthVert);
	}
	// Below
	if (gl_GlobalInvocationID.y > 0) {
		r = pos_in[idx - nParticles.x].xyz - p;
		force += normalize(r) * SpringK * (length(r) - RestLengthVert);
		r2 = pos_in[idx - nParticles.x].xyz + vel_in[idx - nParticles.x].xyz * DeltaT - p2;
		force2 += normalize(r2) * SpringK * (length(r2) - RestLengthVert);
	}
	// Left
	if (gl_GlobalInvocationID.x > 0) {
		r = pos_in[idx - 1].xyz - p;
		force += normalize(r) * SpringK * (length(r) - RestLengthHoriz);
		r2 = pos_in[idx - 1].xyz + vel_in[idx - 1].xyz * DeltaT - p2;
		force2 += normalize(r2) * SpringK * (length(r2) - RestLengthHoriz);
	}
	// Right
	if (gl_GlobalInvocationID.x < nParticles.x - 1) {
		r = pos_in[idx + 1].xyz - p;
		force += normalize(r) * SpringK * (length(r) - RestLengthHoriz);
		r2 = pos_in[idx + 1].xyz + vel_in[idx + 1].xyz * DeltaT - p2;
		force2 += normalize(r2) * SpringK * (length(r2) - RestLengthHoriz);
	}

	// Diagonals
	// Upper-left
	if (gl_GlobalInvocationID.x > 0 && gl_GlobalInvocationID.y < nParticles.y - 1) {
		r = pos_in[idx + nParticles.x - 1].xyz - p;
		force += normalize(r) * SpringK * (length(r) - RestLengthDiag);
		r2 = pos_in[idx + nParticles.x - 1].xyz + vel_in[idx + nParticles.x - 1].xyz * DeltaT - p2;
		force2 += normalize(r2) * SpringK * (length(r2) - RestLengthDiag);
	}
	// Upper-right
	if (gl_GlobalInvocationID.x < nParticles.x - 1 && gl_GlobalInvocationID.y < nParticles.y - 1) {
		r = pos_in[idx + nParticles.x + 1].xyz - p;
		force += normalize(r) * SpringK * (length(r) - RestLengthDiag);
		r2 = pos_in[idx + nParticles.x + 1].xyz + vel_in[idx + nParticles.x + 1].xyz * DeltaT - p2;
		force2 += normalize(r2) * SpringK * (length(r2) - RestLengthDiag);
	}
	// lower -left
	if (gl_GlobalInvocationID.x > 0 && gl_GlobalInvocationID.y > 0) {
		r = pos_in[idx - nParticles.x - 1].xyz - p;
		force += normalize(r) * SpringK * (length(r) - RestLengthDiag);
		r2 = pos_in[idx - nParticles.x - 1].xyz + vel_in[idx - nParticles.x - 1].xyz * DeltaT - p2;
		force2 += normalize(r2) * SpringK * (length(r2) - RestLengthDiag);
	}
	// lower-right
	if (gl_GlobalInvocationID.x < nParticles.x - 1 && gl_GlobalInvocationID.y > 0) {
		r = pos_in[idx - nParticles.x + 1].xyz - p;
		force += normalize(r) * SpringK * (length(r) - RestLengthDiag);
		r2 = pos_in[idx - nParticles.x + 1].xyz + vel_in[idx - nParticles.x + 1].xyz * DeltaT - p2;
		force2 += normalize(r2) * SpringK * (length(r2) - RestLengthDiag);
	}

	// Fd 구하기
	force -= DampingConst * v;							// F1 공기 저항력
	force *= ParticleInvMass;								// 가속도 구하기	

	force2 -= DampingConst * (v + force * DeltaT);		
	force2 *= ParticleInvMass;								// 1차 미분 가속도

	pos_out[idx] = vec4(p + v * DeltaT + 0.5f * force * DeltaT * DeltaT, 1.0f);			// Pi + Vi * h
	vel_out[idx] = vec4(v + 0.5f * (force + force2) * DeltaT, 0.0f);		// Vi + F(Pi) / m * h

	if (gl_GlobalInvocationID.y == nParticles.y - 1 && (
		gl_GlobalInvocationID.x == 0 ||
		gl_GlobalInvocationID.x == nParticles.x / 4 ||
		gl_GlobalInvocationID.x == nParticles.x * 2 / 4 ||
		gl_GlobalInvocationID.x == nParticles.x * 3 / 4 ||
		gl_GlobalInvocationID.x == nParticles.x - 1)) {
		pos_out[idx] = vec4(p, 1.0f);
		vel_out[idx] = vec4(0.0f, 0.0f, 0.0f, 0.0f);
	}
}

void Euler_2nd_order_shared() {

	uvec3 nParticles = gl_NumWorkGroups * gl_WorkGroupSize;
	uint idx = gl_GlobalInvocationID.y * nParticles.x + gl_GlobalInvocationID.x;
	uint sid = (gl_LocalInvocationID.x + 1) + (gl_WorkGroupSize.x + 2) * (gl_LocalInvocationID.y + 1);

	uint shared_size = (gl_WorkGroupSize.x + 2) * (gl_WorkGroupSize.y + 2);

	vec3 p, p2, v, force, force2, r, r2;

	p = pos_in[idx].xyz;
	v = vel_in[idx].xyz;
	p2 = p + v * DeltaT;

	// Fg 구하기
	force = Gravity * ParticleMass;					
	force2 = Gravity * ParticleMass;

	position_shared[sid] = pos_in[idx];
	position_shared[sid + shared_size] = vel_in[idx];

	// left
	if (gl_GlobalInvocationID.x != 0 && gl_LocalInvocationID.x == 0) {
		position_shared[sid - 1] = pos_in[idx - 1];
		position_shared[sid - 1 + shared_size] = vel_in[idx - 1];
	}
	//right
	if (gl_GlobalInvocationID.x != nParticles.x - 1 && gl_LocalInvocationID.x == gl_WorkGroupSize.x - 1) {
		position_shared[sid + 1] = pos_in[idx + 1];
		position_shared[sid + 1 + shared_size] = vel_in[idx + 1];
	}
	// above
	if (gl_GlobalInvocationID.y != 0 && gl_LocalInvocationID.y == 0) {
		position_shared[sid - (gl_WorkGroupSize.x + 2)] = pos_in[idx - nParticles.x];
		position_shared[sid - (gl_WorkGroupSize.x + 2) + shared_size] = vel_in[idx - nParticles.x];
	}
	// below
	if (gl_GlobalInvocationID.y != nParticles.y - 1 && gl_LocalInvocationID.y == gl_WorkGroupSize.y - 1) {
		position_shared[sid + (gl_WorkGroupSize.x + 2)] = pos_in[idx + nParticles.x];
		position_shared[sid + (gl_WorkGroupSize.x + 2) + shared_size] = vel_in[idx + nParticles.x];
	}
	// Diagonals
	// upper-left
	if (gl_GlobalInvocationID.x != 0 && gl_GlobalInvocationID.y != 0 &&
		gl_LocalInvocationID.x == 0 && gl_LocalInvocationID.y == 0) {
		position_shared[sid - 1 - (gl_WorkGroupSize.x + 2)] = pos_in[idx - 1 - nParticles.x];
		position_shared[sid - 1 - (gl_WorkGroupSize.x + 2) + shared_size] = vel_in[idx - 1 - nParticles.x];
	}
	// upper-right
	if (gl_GlobalInvocationID.x != nParticles.x - 1 && gl_GlobalInvocationID.y != 0 &&
		gl_LocalInvocationID.x == gl_WorkGroupSize.x - 1 && gl_LocalInvocationID.y == 0) {
		position_shared[sid + 1 - (gl_WorkGroupSize.x + 2)] = pos_in[idx + 1 - nParticles.x];
		position_shared[sid + 1 - (gl_WorkGroupSize.x + 2) + shared_size] = vel_in[idx + 1 - nParticles.x];
	}
	// lower-left
	if (gl_GlobalInvocationID.x != 0 && gl_GlobalInvocationID.y != nParticles.y - 1 &&
		gl_LocalInvocationID.x == 0 && gl_LocalInvocationID.y == gl_WorkGroupSize.y - 1) {
		position_shared[sid - 1 + (gl_WorkGroupSize.x + 2)] = pos_in[idx - 1 + nParticles.x];
		position_shared[sid - 1 + (gl_WorkGroupSize.x + 2) + shared_size] = vel_in[idx - 1 + nParticles.x];
	}
	// lower-right
	if (gl_GlobalInvocationID.x != nParticles.x - 1 && gl_GlobalInvocationID.y != nParticles.y - 1 &&
		gl_LocalInvocationID.x == gl_WorkGroupSize.x - 1 && gl_LocalInvocationID.y == gl_WorkGroupSize.y - 1) {
		position_shared[sid + 1 + (gl_WorkGroupSize.x + 2)] = pos_in[idx + 1 + nParticles.x];
		position_shared[sid + 1 + (gl_WorkGroupSize.x + 2) + shared_size] = vel_in[idx + 1 + nParticles.x];
	}

	barrier();

	// Fs 구하기
	// Particle above
	if (gl_GlobalInvocationID.y < nParticles.y - 1) {
		uint above_idx = sid + (gl_WorkGroupSize.x + 2);

		r = position_shared[above_idx].xyz - p;
		force += normalize(r) * SpringK * (length(r) - RestLengthVert);
		r2 = position_shared[above_idx].xyz + position_shared[above_idx + shared_size].xyz * DeltaT - p2;
		force2 += normalize(r2) * SpringK * (length(r2) - RestLengthVert);
	}
	// Below
	if (gl_GlobalInvocationID.y > 0) {
		uint below_idx = sid - (gl_WorkGroupSize.x + 2);

		r = position_shared[below_idx].xyz - p;
		force += normalize(r) * SpringK * (length(r) - RestLengthVert);
		r2 = position_shared[below_idx].xyz + position_shared[below_idx + shared_size].xyz * DeltaT - p2;
		force2 += normalize(r2) * SpringK * (length(r2) - RestLengthVert);
	}
	// Left
	if (gl_GlobalInvocationID.x > 0) {
		uint left_idx = sid - 1;

		r = position_shared[left_idx].xyz - p;
		force += normalize(r) * SpringK * (length(r) - RestLengthHoriz);
		r2 = position_shared[left_idx].xyz + position_shared[left_idx + shared_size].xyz * DeltaT - p2;
		force2 += normalize(r2) * SpringK * (length(r2) - RestLengthHoriz);
	}
	// Right
	if (gl_GlobalInvocationID.x < nParticles.x - 1) {
		uint right_idx = sid + 1;

		r = position_shared[right_idx].xyz - p;
		force += normalize(r) * SpringK * (length(r) - RestLengthHoriz);
		r2 = position_shared[right_idx].xyz + position_shared[right_idx + shared_size].xyz * DeltaT - p2;
		force2 += normalize(r2) * SpringK * (length(r2) - RestLengthHoriz);
	}

	// Diagonals
	// Upper-left
	if (gl_GlobalInvocationID.x > 0 && gl_GlobalInvocationID.y < nParticles.y - 1) {
		uint up_left_idx = sid + (gl_WorkGroupSize.x + 2) - 1;

		r = position_shared[up_left_idx].xyz - p;
		force += normalize(r) * SpringK * (length(r) - RestLengthDiag);
		r2 = position_shared[up_left_idx].xyz + position_shared[up_left_idx + shared_size].xyz * DeltaT - p2;
		force2 += normalize(r2) * SpringK * (length(r2) - RestLengthDiag);
	}
	// Upper-right
	if (gl_GlobalInvocationID.x < nParticles.x - 1 && gl_GlobalInvocationID.y < nParticles.y - 1) {
		uint up_right_idx = sid + (gl_WorkGroupSize.x + 2) + 1;

		r = position_shared[up_right_idx].xyz - p;
		force += normalize(r) * SpringK * (length(r) - RestLengthDiag);
		r2 = position_shared[up_right_idx].xyz + position_shared[up_right_idx + shared_size].xyz * DeltaT - p2;
		force2 += normalize(r2) * SpringK * (length(r2) - RestLengthDiag);
	}
	// lower -left
	if (gl_GlobalInvocationID.x > 0 && gl_GlobalInvocationID.y > 0) {
		uint lo_left_idx = sid - (gl_WorkGroupSize.x + 2) - 1;

		r = position_shared[lo_left_idx].xyz - p;
		force += normalize(r) * SpringK * (length(r) - RestLengthDiag);
		r2 = position_shared[lo_left_idx].xyz + position_shared[lo_left_idx + shared_size].xyz * DeltaT - p2;
		force2 += normalize(r2) * SpringK * (length(r2) - RestLengthDiag);
	}
	// lower-right
	if (gl_GlobalInvocationID.x < nParticles.x - 1 && gl_GlobalInvocationID.y > 0) {
		uint lo_right_idx = sid - (gl_WorkGroupSize.x + 2) + 1;

		r = position_shared[lo_right_idx].xyz - p;
		force += normalize(r) * SpringK * (length(r) - RestLengthDiag);
		r2 = position_shared[lo_right_idx].xyz + position_shared[lo_right_idx + shared_size].xyz * DeltaT - p2;
		force2 += normalize(r2) * SpringK * (length(r2) - RestLengthDiag);
	}

	// Fd 구하기
	force -= DampingConst * v;							// F1 공기 저항력															
	force *= ParticleInvMass;								// 가속도 구하기		
	force2 -= DampingConst * (v + force * DeltaT);
	force2 *= ParticleInvMass;								// 1차 미분 가속도

	pos_out[idx] = vec4(p + v * DeltaT + 0.5f * force * DeltaT * DeltaT, 1.0f);			// Pi + Vi * h
	vel_out[idx] = vec4(v + 0.5f * (force + force2) * DeltaT, 0.0f);		// Vi + F(Pi) / m * h

	if (gl_GlobalInvocationID.y == nParticles.y - 1 && (
		gl_GlobalInvocationID.x == 0 ||
		gl_GlobalInvocationID.x == nParticles.x / 4 ||
		gl_GlobalInvocationID.x == nParticles.x * 2 / 4 ||
		gl_GlobalInvocationID.x == nParticles.x * 3 / 4 ||
		gl_GlobalInvocationID.x == nParticles.x - 1)) {
		pos_out[idx] = vec4(p, 1.0f);
		vel_out[idx] = vec4(0.0f, 0.0f, 0.0f, 0.0f);
	}
}

void main(void) {
	if(u_method_flag == 0) 
		Euler_1st_order();
	else if(u_method_flag == 1) 
		Euler_2nd_order();
	else
		Euler_2nd_order_shared();
}
