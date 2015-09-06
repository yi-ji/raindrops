//
//  ModelAssetLoader.swift
//  waterwaterwater
//
//  Created by 郝有峰 on 15/5/11.
//  Copyright (c) 2015年 郝有峰. All rights reserved.
//

import Foundation
import GLKit

/**
载入各类物体的载入函数集合
*/
class ModelAssetLoader {
    
    private var _texture: Texture?
    var texture: Texture {
        get {
            if self._texture == nil {
                let textureFileArray = [
                    NSBundle.mainBundle().pathForResource("fushi-blur", ofType: "jpeg")!,
                    NSBundle.mainBundle().pathForResource("fushi-blur", ofType: "jpeg")!,
                    NSBundle.mainBundle().pathForResource("fushi-blur", ofType: "jpeg")!,
                    NSBundle.mainBundle().pathForResource("fushi-blur", ofType: "jpeg")!,
                    NSBundle.mainBundle().pathForResource("fushi-mirror", ofType: "jpeg")!,
                    NSBundle.mainBundle().pathForResource("fushi-blur", ofType: "jpeg")!,

//                    NSBundle.mainBundle().pathForResource("front-blur", ofType: "jpeg")!,
//                    NSBundle.mainBundle().pathForResource("front-blur", ofType: "jpeg")!,
//                    NSBundle.mainBundle().pathForResource("front-blur", ofType: "jpeg")!,
//                    NSBundle.mainBundle().pathForResource("front-blur", ofType: "jpeg")!,
//                    NSBundle.mainBundle().pathForResource("front-mirror", ofType: "jpeg")!,
//                    NSBundle.mainBundle().pathForResource("front-blur", ofType: "jpeg")!,
                    
//                    NSBundle.mainBundle().pathForResource("right", ofType: "jpg")!,
//                    NSBundle.mainBundle().pathForResource("left", ofType: "jpg")!,
//                    NSBundle.mainBundle().pathForResource("top", ofType: "jpg")!,
//                    NSBundle.mainBundle().pathForResource("bottom", ofType: "jpg")!,
//                    NSBundle.mainBundle().pathForResource("back", ofType: "jpg")!,
//                    NSBundle.mainBundle().pathForResource("front", ofType: "jpg")!,
                ]
                
                let options: NSDictionary = [GLKTextureLoaderOriginBottomLeft: false]
                
                var error: NSError?
                var cubemapTexture: GLKTextureInfo? = GLKTextureLoader.cubeMapWithContentsOfFiles(textureFileArray, options: options as [NSObject : AnyObject], error: &error)
                
                if (cubemapTexture == nil) {
                    NSLog("Failure reason: %@", error!.description)
                    NSLog("Error code: %i", error!.code)
                    NSLog("Textures: %@", textureFileArray)
                }
                
                self._texture = Texture(textureInfo: cubemapTexture!)
            }
            return self._texture!
        }
    }
    
    private var _skyboxAsset: ModelAsset?
    var skyboxAsset: ModelAsset {
        get {
            if self._skyboxAsset == nil {
                self._skyboxAsset = self.skyboxAssetLoader()
                self._skyboxAsset?.texture = self.texture
            }
            return self._skyboxAsset!
        }
    }
    
    private var _dropletAsset: ModelAsset?
    var dropletAsset: ModelAsset {
        get {
            if self._dropletAsset == nil {
                self._dropletAsset = self.dropletAssetLoader()
                self._dropletAsset?.texture = self.texture
            }
            return self._dropletAsset!
        }
    }
    
    private func skyboxAssetLoader() -> ModelAsset {
        let vertexData: [GLfloat] = [
            // Positions
            -1.0,  1.0, -1.0,
            -1.0, -1.0, -1.0,
            1.0, -1.0, -1.0,
            1.0, -1.0, -1.0,
            1.0,  1.0, -1.0,
            -1.0,  1.0, -1.0,
            
            -1.0, -1.0,  1.0,
            -1.0, -1.0, -1.0,
            -1.0,  1.0, -1.0,
            -1.0,  1.0, -1.0,
            -1.0,  1.0,  1.0,
            -1.0, -1.0,  1.0,
            
            1.0, -1.0, -1.0,
            1.0, -1.0,  1.0,
            1.0,  1.0,  1.0,
            1.0,  1.0,  1.0,
            1.0,  1.0, -1.0,
            1.0, -1.0, -1.0,
            
            -1.0, -1.0,  1.0,
            -1.0,  1.0,  1.0,
            1.0,  1.0,  1.0,
            1.0,  1.0,  1.0,
            1.0, -1.0,  1.0,
            -1.0, -1.0,  1.0,
            
            -1.0,  1.0, -1.0,
            1.0,  1.0, -1.0,
            1.0,  1.0,  1.0,
            1.0,  1.0,  1.0,
            -1.0,  1.0,  1.0,
            -1.0,  1.0, -1.0,
            
            -1.0, -1.0, -1.0,
            -1.0, -1.0,  1.0,
            1.0, -1.0, -1.0,
            1.0, -1.0, -1.0,
            -1.0, -1.0,  1.0,
            1.0, -1.0,  1.0
        ]
        let modelAsset = ModelAsset()
        let shaderProgram = modelAsset.shaderProgram
        shaderProgram.loadShaders("Skybox", "Skybox")
        modelAsset.drawCount = 6 * 6
        modelAsset.drawStart = 0
        modelAsset.drawType = GLenum(GL_TRIANGLES)
        
        glGenVertexArraysOES(1, &modelAsset.vao)
        glBindVertexArrayOES(modelAsset.vao)
        
        glGenBuffers(1, &modelAsset.vbo)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), modelAsset.vbo)
        
        glBufferData(GLenum(GL_ARRAY_BUFFER), vertexData.bufferSize, vertexData, GLenum(GL_STATIC_DRAW))
        
        glEnableVertexAttribArray(shaderProgram.attrib("vert"))
        glVertexAttribPointer(shaderProgram.attrib("vert"), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, unsafeBufferOffset(0))
        
        glBindVertexArrayOES(0)
        
        return modelAsset
    }
    
    /// 载入雨滴类
    private func dropletAssetLoader() -> ModelAsset {
        let modelAsset = ModelAsset()
        let shaderProgram = modelAsset.shaderProgram
        let vertexData: [GLfloat] = [
            //采用(http://stackoverflow.com/questions/10488086/drawing-a-sphere-in-opengl-es?rq=1)方法画球，故只需要正方形的几个顶点即可
            // x, y, z
            -1, -1, 0,
            -1, 1, 0,
            1, 1, 0,
            
            1, 1, 0,
            1, -1, 0,
            -1, -1, 0
        ]
        modelAsset.shaderProgram.loadShaders("Droplet", "Droplet")
        modelAsset.drawStart = 0
        modelAsset.drawCount = 2 * 3
        modelAsset.drawType = GLenum(GL_TRIANGLES)
        
        glGenVertexArraysOES(1, &modelAsset.vao)
        glBindVertexArrayOES(modelAsset.vao)
        
        glGenBuffers(1, &modelAsset.vbo)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), modelAsset.vbo)
        
        glBufferData(GLenum(GL_ARRAY_BUFFER), vertexData.bufferSize, vertexData, GLenum(GL_STATIC_DRAW))
        
        glEnableVertexAttribArray(shaderProgram.attrib("vert"))
        glVertexAttribPointer(shaderProgram.attrib("vert"), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, unsafeBufferOffset(0))
        
        
        glBindVertexArrayOES(0)
        
        return modelAsset
    }
    
    static private var _stainShader: ShaderProgram?
    static var stainShader: ShaderProgram {
        get {
            if self._stainShader == nil {
                self._stainShader = ShaderProgram()
                self._stainShader!.loadShaders("Stain", "Stain")
            }
            return self._stainShader!
        }
    }
    static func stainAssetLoader(droplet: DropletModel) -> ModelAsset {
        let modelAsset = ModelAsset()
        let dropletCurve = MathUtils.dropletEdgeCurve(droplet)
        let vertexData: [GLfloat] = MathUtils.getTriangles(dropletCurve)
        modelAsset.shaderProgram = self.stainShader
        modelAsset.drawStart = 0
        modelAsset.drawCount = GLint(vertexData.count)
        modelAsset.drawType = GLenum(GL_TRIANGLE_FAN)
        
        let shaderProgram = modelAsset.shaderProgram
        glGenVertexArraysOES(1, &modelAsset.vao)
        glBindVertexArrayOES(modelAsset.vao)
        
        glGenBuffers(1, &modelAsset.vbo)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), modelAsset.vbo)
        
        glBufferData(GLenum(GL_ARRAY_BUFFER), vertexData.bufferSize, vertexData, GLenum(GL_STATIC_DRAW))
        
        glEnableVertexAttribArray(shaderProgram.attrib("vert"))
        glVertexAttribPointer(shaderProgram.attrib("vert"), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, unsafeBufferOffset(0))
        
        
        glBindVertexArrayOES(0)
        
        return modelAsset
    }
}
