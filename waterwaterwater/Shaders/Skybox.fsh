//
//  Shader.fsh
//  waterwaterwater
//
//  Created by 郝有峰 on 15/5/3.
//  Copyright (c) 2015年 郝有峰. All rights reserved.
//
precision highp float;

varying vec3 textureCoord;
uniform samplerCube skybox;
void main()
{
    gl_FragColor = textureCube(skybox, textureCoord);
}
