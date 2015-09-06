precision highp float;

attribute vec3 vert;

varying vec3 fragVert;

uniform float radius;
uniform mat4 modelMatrix;
uniform mat4 cameraMatrix;
uniform float contactAngle;

void main() {
    vec3 realVert = vert;
    realVert.x = realVert.x * radius * sin(contactAngle);
    realVert.y = realVert.y * radius * sin(contactAngle);
    
    fragVert = realVert;
    
    gl_Position = cameraMatrix * modelMatrix * vec4(realVert, 1.0);
}