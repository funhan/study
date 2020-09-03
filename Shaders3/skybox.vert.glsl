#version 430

uniform mat4 u_ModelViewProjectionMatrix;

layout(location = 0) in vec3 a_position;

out vec3 v_position;

void main(void) {
	v_position = vec3(a_position.x, -a_position.y, a_position.z);
	vec4 tmp = u_ModelViewProjectionMatrix * vec4(a_position, 1.0f);
	gl_Position = tmp.xyww;
	//gl_Position = u_ModelViewProjectionMatrix * vec4(a_position, 1.0f);
}