//
//  SphereBuilder.swift
//  waterwaterwater
//
//  Created by 郝有峰 on 15/5/7.
//  Copyright (c) 2015年 郝有峰. All rights reserved.
//

import Foundation
import GLKit

protocol Drawer {
    var description: String { get }
    var modelAsset: ModelAsset? { get set }
    var transform: GLKMatrix4 { get }
}

/**
表示一类物体，包含以下内容:

 shaderProgram(可能为nil）
 texture（可能为nil)
 vao
 vbo
 glDrawArrays(drawType, drawStart, drawCount)需要的变量
*/
class ModelAsset {
    
    var shaderProgram: ShaderProgram = ShaderProgram()
    var texture: Texture?
    var vao: GLuint = 0
    var vbo: GLuint = 0
    var drawType: GLenum = GLenum(GL_TRIANGLES)
    var drawStart: GLint = 0
    var drawCount: GLint = 0
    
    deinit {
        
        glDeleteBuffers(1, &self.vbo)
        glDeleteVertexArraysOES(1, &self.vao)
    }
}

/**
表示一个水滴实例，包含以下内容:

 modelAsset: 一类雨滴
 radius: 球缺对应球半径
 contactAngle: 球缺与底面接触角
 transform: 变换矩阵
 description: 描述
*/
class DropletInstance: Drawer {
    

    var modelAsset: ModelAsset?
    
    var interpolateVars = [[GLfloat]]()
    var velocity = GLKVector3Make(0.0, 0.0, 0.0)
    var acceleration = GLKVector3Make(0, 0, 0)
    var radius: GLfloat = 0.1
    var position: GLKVector3 = GLKVector3Make(0, 0, 0.0)
    var contactAngle: GLfloat = GLfloat(M_PI) / 4
    var color: GLKVector4 = GLKVector4Make(0.0, 0.0, 0.0, 1.0)
    var transform: GLKMatrix4 {
        get {
            let scale = GLKMatrix4MakeScale(1, 1, 1)
            let translate = GLKMatrix4MakeTranslation(self.position.x, self.position.y, self.position.z)
            return GLKMatrix4Multiply(translate, scale)
        }
    }
    var shininess: GLfloat = 100.0
    var specularColor: GLKVector3 = GLKVector3Make(1.0, 1.0, 1.0)

    var description: String {
        get {
            return "Droplet with radius: \(self.radius) contact angle: \(self.contactAngle) and transform matrix \(self.transform.array)"
        }
    }
    
}

/**
表示一个天空盒实例，包含以下内容:

modelAsset: skybox的model类
transform: 变换矩阵
description: 描述
*/
class SkyboxInstance: Drawer {
    
    var modelAsset: ModelAsset?
    
    var transform: GLKMatrix4 = GLKMatrix4MakeTranslation(0, 0, 0)
    
    var description: String {
        get {
            return "Cube"
        }
    }
}

/**
表示一个水痕实例，包含以下内容:

modelAsset: 一类雨滴
radius: 球缺对应球半径
contactAngle: 球缺与底面接触角
transform: 变换矩阵
description: 描述
*/
class StainInstance: Drawer {
    
    
    var modelAsset: ModelAsset?
    
    var velocity: GLKVector3 = GLKVector3Make(0, 0, 0.0)
    var acceleration: GLKVector3 = GLKVector3Make(0, 0, 0.0)
    var interpolateVars = [[GLfloat]]()
    var radius: GLfloat = 0.1
    var position: GLKVector3 = GLKVector3Make(0, 0, 0.0)
    var contactAngle: GLfloat = GLfloat(M_PI) / 4
    var color: GLKVector4 = GLKVector4Make(1.0, 1.0, 1.0, 1.0)
    var ratio: GLfloat = 1.0
    var transform: GLKMatrix4 {
        get {
            let scale = GLKMatrix4MakeScale(ratio, ratio, 1)
            let translate = GLKMatrix4MakeTranslation(self.position.x, self.position.y, self.position.z)
            return GLKMatrix4Multiply(translate, scale)
        }
    }

    var description: String {
        get {
            return "Stain with radius: \(self.radius) contact angle: \(self.contactAngle) and transform matrix \(self.transform.array)"
        }
    }
    
}
