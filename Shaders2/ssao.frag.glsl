#version 430

#define KERNEL_SIZE 64
#define RAND_DIR_SIZE 128

// uniform
layout(binding = 0) uniform sampler2D u_PositionTex;
layout(binding = 1) uniform sampler2D u_NormalTex;
layout(binding = 8) uniform sampler2D u_RandDirTex;

uniform mat4 u_ProjectionMatrix;

uniform vec3 u_SampleKernel[KERNEL_SIZE];
uniform int u_width;
uniform int u_height;

const float Radius = 2.55f;
// tile noise texture over screen based on screen dimensions divided by noise size
const vec2 noiseScale = vec2(float(u_width) / RAND_DIR_SIZE, float(u_height) / RAND_DIR_SIZE);

// input
in vec2 v_tex_coord;

// output
layout(location = 0) out vec3 AoData; 
// float가 아닌 vec3인 것은 출력 결과가 빨간색이 아니라 하얀색으로 보기위함.
// 이를 수정하면 메모리 절약할 수 있음.

void main(void) {	
	// Create the random tangent space matrix.
	vec3 randDir = normalize(texture(u_RandDirTex, v_tex_coord * noiseScale).xyz);
	vec3 normal = normalize(texture(u_NormalTex, v_tex_coord).xyz);
	vec3 biTang = cross(normal, randDir);

	if (length(biTang) < 0.0001)
		biTang = cross(normal, vec3(0.0f, 0.0f, 1.0f));
	biTang = normalize(biTang);

	vec3 tang = cross(biTang, normal);
	mat3 toCamSpace = mat3(tang, biTang, normal);
	
	float occlusionSum = 0.0f;

	vec3 camPos = texture(u_PositionTex, v_tex_coord).xyz;

	for (int i = 0; i < KERNEL_SIZE; ++i) {
		vec3 samplePos = camPos + Radius * (toCamSpace * u_SampleKernel[i]);

		//vec4 p = u_ProjectionMatrix * vec4(samplePos, 1);  // from view to clip-space
		//p *= 1.0 / p.w;                                    // perspective divide  
		//p.xyz = p.xyz * 0.5 + 0.5;						 // transform to range 0.0 - 1.0  
		//float surfaceZ = texture(u_PositionTex, p.xy).z;	 

		vec4 p = u_ProjectionMatrix * vec4(samplePos, 1.0f); // u_ProjectionMatrix = bias * proj;

		// Access camera space z-coordinate at that point
		float surfaceZ = textureProj(u_PositionTex, p).z;
		float zDist = surfaceZ - camPos.z;

		// Count points that ARE occluded
		if (zDist >= 0.0 && zDist <= Radius && surfaceZ > samplePos.z)
			occlusionSum += 1.0f;
	}
	float occ = 1.0f - occlusionSum / KERNEL_SIZE;
	occ = pow(occ, 4);
	AoData = vec3(occ);
}
