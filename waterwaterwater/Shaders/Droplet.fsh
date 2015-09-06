precision highp float;
precision highp int;
#define M_PI 3.1415926535897932384626433832795

varying vec3 fragVert;

uniform float radius;
uniform mat3 normalMatrix;
uniform vec4 materialColor;
uniform mat4 modelMatrix;
uniform vec3 cameraPosition;
uniform samplerCube skybox;
uniform float refractRatio;
uniform float materialShininess;
uniform vec3 materialSpecularColor;
uniform float contactAngle;
uniform vec3 velocity;
uniform vec3 acceleration;
uniform vec4 RGB;

#define MAX_INTERPOLATE_N 20
// 得到0到2Pi的差值噪声
uniform int numInterpolate;
uniform struct Interpolate {
    float a;
    float b;
    float c;
    float d;
} interpolate[MAX_INTERPOLATE_N];
float getInterpolateNoise(float rad) {
    float fnum =  float(numInterpolate);
    int j = int(floor(rad * fnum/ (2.0 * M_PI)));
    float xj = float(j) * 2.0 * M_PI / fnum;
    float a = interpolate[j].a;
    float b = interpolate[j].b;
    float c = interpolate[j].c;
    float d = interpolate[j].d;
    float t = rad - xj;
    return a + b * t + c * pow(t, 2.0) + d * pow(t, 3.0);
}

#define MAX_LIGHTS 10
uniform int numLights;
uniform struct Light {
    vec4 position;
    vec3 intensities; //a.k.a the color of the light
    float attenuation;
    float ambientCoefficient;
    float coneAngle;
    vec3 coneDirection;
} lights[MAX_LIGHTS];


// 水滴形形变, 极坐标
float dropletShape(vec2 vXY, vec2 velocity, vec2 acceleration) {

    float maxV = 0.3;
    float velocityLength = min(length(velocity), maxV);
    float p = -0.7 + (0.70 - 0.60) * velocityLength / maxV;
    float m = 0.05 + (0.2 - 0.05) * velocityLength / maxV;
    float q = 0.7 + (1.0 - 0.7) * velocityLength / maxV;
    float rad = atan(vXY.y, vXY.x);
    if (rad < 0.0) rad += 2.0 * M_PI;
    float noiseDeform = getInterpolateNoise(rad);
    float vecRad = atan(velocity.y, velocity.x);
    if (rad < 0.0) vecRad += 2.0 * M_PI;
    if (velocity.x != 0.0 || velocity.y != 0.0) {
        rad -= vecRad - 3.0 * M_PI / 2.0;
    }
    
//    float accRad = atan(acceleration.y, acceleration.x);
//    accRad += M_PI;
//    if (acceleration.x != 0.0 || acceleration.y != 0.0) {
//        rad -= accRad - 3.0 * M_PI / 2.0;
//    }
    rad = rad + ceil(-rad / (2.0 * M_PI)) * 2.0 * M_PI;
    return sqrt(pow(abs(p*cos(rad) + m*sin(rad)*cos(rad)), 2.0) + pow(abs(q*sin(rad)), 2.0)) * noiseDeform;
}

vec3 ApplyLight(Light light, vec3 surfaceColor, vec3 normal, vec3 surfacePos, vec3 surfaceToCamera) {
    vec3 surfaceToLight;
    float attenuation = 1.0;
    if (light.position.w == 0.0) {
        //directional light
        surfaceToLight = normalize(light.position.xyz);
        attenuation = 1.0; //no attenuation for directional lights
    } else {
        //point light
        surfaceToLight = normalize(light.position.xyz - surfacePos);
        float distanceToLight = length(light.position.xyz - surfacePos);
        attenuation = 1.0 / (1.0 + light.attenuation * pow(distanceToLight, 2.0));
        
        //cone restrictions (affects attenuation)
        float lightToSurfaceAngle = degrees(acos(dot(-surfaceToLight, normalize(light.coneDirection))));
        if(lightToSurfaceAngle > light.coneAngle){
            attenuation = 0.0;
        }
    }
    
    //ambient
    vec3 ambient = light.ambientCoefficient * surfaceColor.rgb * light.intensities;
    
    //diffuse
    float diffuseCoefficient = max(0.0, dot(normal, surfaceToLight));
    vec3 diffuse = diffuseCoefficient * surfaceColor.rgb * light.intensities;
    
    //specular
    float specularCoefficient = 0.0;
    if(diffuseCoefficient > 0.0)
        specularCoefficient = pow(max(0.0, dot(surfaceToCamera, reflect(-surfaceToLight, normal))), materialShininess);
    vec3 specular = specularCoefficient * materialSpecularColor * light.intensities;
    
    //linear color (color before gamma correction)
    return ambient + attenuation*(diffuse + specular);
}

void main() {
    
    float distanceFromCenter = length(fragVert.xy);
    float dropletShapeDeform = dropletShape(fragVert.xy, velocity.xy, acceleration.xy);
    float deformRatio = dropletShapeDeform;
    // Establish the visual bounds of the sphere
    if (distanceFromCenter > radius * cos(contactAngle) * deformRatio) {
        discard;
    }
    
    vec3 deformedVert = fragVert / deformRatio;
    float deformedDistance = length(deformedVert.xy);
    
    float rad = asin(deformedDistance / radius);
    float originHeight = radius * cos(rad);
    float hiddenHeight = radius * cos(contactAngle);
    float realZ = originHeight - hiddenHeight;
    
    // Calculate the lighting normal for the sphere
    vec2 transformedXY = (modelMatrix * vec4(fragVert, 1)).xy;
    vec3 surfacePos = vec3(transformedXY, realZ);
    vec3 fragNormal = normalize(vec3(fragVert.xy, originHeight));
    vec3 normal = normalize(normalMatrix * fragNormal);
    vec4 surfaceColor = materialColor;
    vec3 surfaceToCamera = normalize(cameraPosition - surfacePos);
    
    vec3 linearColor = vec3(0);
    for (int i = 0; i < numLights; i++) {
        linearColor += ApplyLight(lights[i], surfaceColor.rgb, normal, surfacePos, surfaceToCamera);
    }
    
    //first refract on the top layer
    vec3 incidentLightVector = normalize(surfacePos - cameraPosition);
    vec3 refractLightVectorToBottom = refract(incidentLightVector, normal, refractRatio);
    vec2 bottomPoint = surfacePos.xy + refractLightVectorToBottom.xy * surfacePos.z / abs(refractLightVectorToBottom.z);
    //second refract on the bottom layer
    vec3 refractLightVectorToCubemap = refract(refractLightVectorToBottom, vec3(0, 0, 1), 1.0 / refractRatio);
    refractLightVectorToCubemap /=  abs(refractLightVectorToCubemap.z);
    refractLightVectorToCubemap.xy += bottomPoint;
//    if (refractLightVectorToCubemap.x < 0.00 && refractLightVectorToCubemap.y < 0.00) {
//        gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
//        return;
//    }
    vec4 textureRefractedColor = textureCube(skybox, refractLightVectorToCubemap);
    
    linearColor += textureRefractedColor.rgb;
//    //final color (after gamma correction)
//    vec3 gamma = vec3(1.0/2.2);
//    gl_FragColor = vec4(pow(linearColor, gamma), surfaceColor.a);
    vec4 color = vec4(linearColor, surfaceColor.a);
    vec4 ratio = RGB + vec4(1.0, 1.0, 1.0, 1.0);
    vec4 progressedColor = vec4(color.r * ratio.r, color.g * ratio.g, color.b * ratio.b, color.a * ratio.a);
    gl_FragColor = progressedColor;

}