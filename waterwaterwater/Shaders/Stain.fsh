precision highp float;


varying vec3 fragVert;

uniform samplerCube skybox;
uniform vec4 RGB;
void main() {
    vec3 temp = fragVert;
//    vec3 temp = fragVert - cameraPosition;
//    temp.z = -temp.z;
//    temp = (cameraMatrix * vec4(temp, 1.0)).xyz;
    vec4 color = textureCube(skybox, temp);
    vec4 ratio = RGB + vec4(1.0, 1.0, 1.0, 1.0);
    vec4 progressedColor = vec4(color.r * ratio.r, color.g * ratio.g, color.b * ratio.b, color.a * ratio.a);
    gl_FragColor =  progressedColor;
}