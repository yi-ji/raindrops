//
//  Texture.swift
//  waterwaterwater
//
//  Created by 郝有峰 on 15/5/7.
//  Copyright (c) 2015年 郝有峰. All rights reserved.
//

import Foundation
import GLKit

class Texture {
    
    private func deleteTexture() -> Void {
        var name = self._textureInfo.name
        glDeleteTextures(1, &name)
    }
    
    private var _textureInfo: GLKTextureInfo
    
    init(textureInfo: GLKTextureInfo) {
        self._textureInfo = textureInfo
    }
    
    deinit {
        self.deleteTexture()
    }
    
    var textureInfo: GLKTextureInfo {
        get {
            return self._textureInfo
        }
    }
    
    let textureUnit: GLint = 0
    
    func useTexture() -> Void {
        glActiveTexture(GLenum(GL_TEXTURE0 + self.textureUnit))
        glBindTexture(self.textureInfo.target, self.textureInfo.name)
    }
    
}