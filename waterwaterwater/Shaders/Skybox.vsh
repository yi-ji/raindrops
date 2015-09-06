//
//  Shader.vsh
//  waterwaterwater
//
//  Created by 郝有峰 on 15/5/3.
//  Copyright (c) 2015年 郝有峰. All rights reserved.
//
precision highp float;

attribute vec3 vert;

varying vec3 textureCoord;

uniform mat4 cameraMatrix;

void main()
{
    
    textureCoord = vert;
    
    gl_Position = cameraMatrix * vec4(vert, 1);
}
