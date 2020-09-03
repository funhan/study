#version 430

// uniform
layout(binding = 6) uniform sampler2D AoTex;

// output
layout(location = 0) out vec3 AoData; // float가 아닌 vec3인 것은 출력 결과가 빨간색이 아니라 하얀색으로 보기위함.

void main(void) {	
	ivec2 pix = ivec2(gl_FragCoord.xy);
	float sum = 0.0f;
	for (int x = -1; x <= 1; ++x) {
		for (int y = -1; y <= 1; ++y) {
			sum += texelFetchOffset(AoTex, pix, 0, ivec2(x, y)).r;
		}
	}
	float ao = sum * (1.0f / 9.0f);
	AoData = vec3(ao);
}
