precision highp float;

attribute vec3 vert;
varying vec3 fragVert;

uniform mat4 modelMatrix;
uniform mat4 cameraMatrix;
uniform float ratio;
uniform vec3 cameraPosition;

void main() {
    vec4 position = (cameraMatrix * modelMatrix * vec4(vert, 1.0));
    fragVert = vec3(position.x * ratio, position.y, cameraPosition.z);
    gl_Position = position;
}