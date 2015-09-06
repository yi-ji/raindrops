//
//  Light.swift
//  waterwaterwater
//
//  Created by 郝有峰 on 15/5/7.
//  Copyright (c) 2015年 郝有峰. All rights reserved.
//

import Foundation
import GLKit

/**
表示一个光源
*/
struct Light {
    
    static let MAX_LIGHT_NUM: GLint = 10
    var position: GLKVector4 = GLKVector4Make(0, 0, 4, 1)
    var intensities: GLKVector3 = GLKVector3()
    var attenuation: GLfloat = 1.0
    var ambientCoefficient: GLfloat = 1.0
    var coneAngle: GLfloat = 0.0
    var coneDirection: GLKVector3 = GLKVector3()
    
}
