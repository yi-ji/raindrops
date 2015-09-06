//
//  Render.swift
//  waterwaterwater
//
//  Created by 郝有峰 on 15/5/9.
//  Copyright (c) 2015年 郝有峰. All rights reserved.
//

import Foundation
import GLKit

/**
渲染物体实例
*/
class Render {
    
    // 初始化Render
    init() {
    
//        let spotlight: Light = {
//            var light: Light = Light()
//            light.position = GLKVector4Make(0, 0, 2, 1)
//            light.intensities = GLKVector3Make(0.1, 0.1, 0.1)
//            light.attenuation = 0.5
//            light.ambientCoefficient = 0.0 //no ambient light
//            light.coneAngle = 80
//            light.coneDirection = GLKVector3Make(0, 0, -5)
//            return light
//            }()
//        self.lights.append(spotlight)
        
        let directionalLight: Light = {
            var light: Light = Light()
            light.position = GLKVector4Make(0, 0, 5, 0) //w == 0 indications a directional light
            light.intensities = GLKVector3Make(0.1, 0.1, 0.1) //weak yellowish light
            light.ambientCoefficient = 1.0
            return light
            }()
        self.lights.append(directionalLight)
        
        let pointLight: Light = {
            var light: Light = Light()
            light.position = GLKVector4Make(0, 0, 5, 1) //w == 0 indications a directional light
            light.intensities = GLKVector3Make(0.1, 0.1, 0.1) //weak yellowish light
            light.ambientCoefficient = 0.0
            return light
            }()
        self.lights.append(pointLight)
//        let directionalLight1: Light = {
//            var light: Light = Light()
//            light.position = GLKVector4Make(0, 5, 0, 0) //w == 0 indications a directional light
//            light.intensities = GLKVector3Make(0.2, 0.2, 0.2) //weak yellowish light
//            light.ambientCoefficient = 0
//            return light
//            }()
//        self.lights.append(directionalLight1)
//        
//        let directionalLight2: Light = {
//            var light: Light = Light()
//            light.position = GLKVector4Make(5, 0, 0, 0) //w == 0 indications a directional light
//            light.intensities = GLKVector3Make(0.2, 0.2, 0.2) //weak yellowish light
//            light.ambientCoefficient = 0
//            return light
//            }()
//        self.lights.append(directionalLight2)
    }
    
    let camera = Camera()
    var lights: [Light] = []
    
    let modelAssetLoader = ModelAssetLoader()
    private var _skybox: SkyboxInstance?
    var skybox: SkyboxInstance {
        get {
            if self._skybox == nil {
                self._skybox = SkyboxInstance()
                self._skybox!.modelAsset = modelAssetLoader.skyboxAsset
            }
            return self._skybox!
        }
    }
    func RenderSkybox() {
        if let asset = self.skybox.modelAsset {
            let shaderProgram = asset.shaderProgram
            
            if !shaderProgram.isInUse() {
                shaderProgram.useProgram()
            }
            
            var previousDepthFunc: GLint = 0
            glGetIntegerv(GLenum(GL_DEPTH_FUNC), &previousDepthFunc)
            
            glDepthFunc(GLenum(GL_LEQUAL))
            
            asset.texture!.useTexture()
            
            shaderProgram.setUniform("skybox", asset.texture!.textureUnit)
            shaderProgram.setUniform("cameraMatrix", camera.matrix)
            
            glBindVertexArrayOES(asset.vao)
            glDrawArrays(asset.drawType, asset.drawStart, asset.drawCount)
            glBindVertexArrayOES(0)
            
            glDepthFunc(GLenum(previousDepthFunc))
            
        } else {
            NSLog("Null modelAsset in %@", self.skybox.description)
        }
    }
    
    
    private var _droplet: DropletInstance?
    var droplet: DropletInstance {
        get {
            if self._droplet == nil {
                self._droplet = DropletInstance()
                self._droplet!.modelAsset = modelAssetLoader.dropletAsset
            }
            return self._droplet!
        }
    }
    func RenderDroplet(let dropletModel: DropletModel) {
        
        // 读取要绘制的dropletModel的信息至dropletInstance
        self.droplet.radius = dropletModel.radius
        self.droplet.position = dropletModel.position
        self.droplet.contactAngle = dropletModel.contactAngle
        self.droplet.velocity = dropletModel.velocity
        self.droplet.interpolateVars = dropletModel.interpolateVars
        self.droplet.acceleration = dropletModel.acceleration
        let previousAcce = dropletModel.previousAcce
        let previousVel = dropletModel.previousVel
        let color = dropletModel.color
        
        let asset = self.droplet.modelAsset
        let shaderProgram = asset!.shaderProgram
        
        if !shaderProgram.isInUse() {
            shaderProgram.useProgram()
        }

        let normalMatrix = GLKMatrix3Transpose(GLKMatrix4GetMatrix3(self.droplet.transform).invert)
        
        asset!.texture!.useTexture()
        
        shaderProgram.setUniform("radius", self.droplet.radius)
        shaderProgram.setUniform("refractRatio", 1 / GLfloat(2.0))
        shaderProgram.setUniform("skybox", asset!.texture!.textureUnit)
        shaderProgram.setUniform("modelMatrix", self.droplet.transform)
        shaderProgram.setUniform("normalMatrix", normalMatrix)
        shaderProgram.setUniform("cameraMatrix", self.camera.matrix)
        shaderProgram.setUniform("materialColor", self.droplet.color)
        shaderProgram.setUniform("materialShininess", self.droplet.shininess)
        shaderProgram.setUniform("materialSpecularColor", self.droplet.specularColor)
        shaderProgram.setUniform("cameraPosition", self.camera.position)
        shaderProgram.setUniform("numLights", GLint(self.lights.count))
        shaderProgram.setUniform("contactAngle", self.droplet.contactAngle)
        shaderProgram.setUniform("RGB", color)

//        if (GLKVector3Length(self.droplet.velocity) > DropletModel.Constants.minVelocity) {
//            shaderProgram.setUniform("velocity", self.droplet.velocity)
//        } else {
            shaderProgram.setUniform("velocity", previousVel)
//        }
//        
//        if (GLKVector3Length(self.droplet.acceleration) > DropletModel.Constants.minAcceleration) {
//            shaderProgram.setUniform("acceleration", self.droplet.acceleration)
//        } else {
            shaderProgram.setUniform("acceleration", previousAcce)
//        }
        for (index, light) in enumerate(self.lights) {
            shaderProgram.setUniform("lights[\(index)].position", light.position)
            shaderProgram.setUniform("lights[\(index)].intensities", light.intensities)
            shaderProgram.setUniform("lights[\(index)].attenuation", light.attenuation)
            shaderProgram.setUniform("lights[\(index)].ambientCoefficient", light.ambientCoefficient)
            shaderProgram.setUniform("lights[\(index)].coneAngle", light.coneAngle)
            shaderProgram.setUniform("lights[\(index)].coneDirection", light.coneDirection)
        }
        
        shaderProgram.setUniform("numInterpolate", GLint(self.droplet.interpolateVars.count))
        for (index, interpolate) in enumerate(self.droplet.interpolateVars) {
            shaderProgram.setUniform("interpolate[\(index)].a", interpolate[0])
            shaderProgram.setUniform("interpolate[\(index)].b", interpolate[1])
            shaderProgram.setUniform("interpolate[\(index)].c", interpolate[2])
            shaderProgram.setUniform("interpolate[\(index)].d", interpolate[3])
        }
        glBindVertexArrayOES(asset!.vao)
        glDrawArrays(asset!.drawType, asset!.drawStart, asset!.drawCount)
        glBindVertexArrayOES(0)
        
    }
    
    
    func RenderStain(let stainModel: StainModel) {
        
        // 读取要绘制的dropletModel的信息至dropletInstance
        let asset = stainModel.stainAsset
        let shaderProgram = asset.shaderProgram
        let color = stainModel.color
        if !shaderProgram.isInUse() {
            shaderProgram.useProgram()
        }
        let normalMatrix = GLKMatrix3Transpose(GLKMatrix4GetMatrix3(stainModel.transform).invert)

        shaderProgram.setUniform("skybox", skybox.modelAsset!.texture!.textureUnit)
        shaderProgram.setUniform("modelMatrix", stainModel.transform)
        shaderProgram.setUniform("cameraMatrix", self.camera.matrix)
        shaderProgram.setUniform("cameraPosition", self.camera.position)
        shaderProgram.setUniform("ratio", self.camera.viewportAspectRatio)
        shaderProgram.setUniform("RGB", color)

        glBindVertexArrayOES(asset.vao)
        glDrawArrays(asset.drawType, asset.drawStart, asset.drawCount)
        glBindVertexArrayOES(0)
        
    }

}