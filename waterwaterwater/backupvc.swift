//
//  backupvc.swift
//  waterwaterwater
//
//  Created by 郝有峰 on 15/5/4.
//  Copyright (c) 2015年 郝有峰. All rights reserved.
//
import Foundation

import GLKit

/// Uniform index.
private enum Uniform {
    case ModelViewProjectionMatrix, NormalMatrix
}
private var gUniforms: [Uniform: GLint] = [:]


extension GLKMatrix3 {
    var array: [Float] {
        return (0..<9).map { i in
            self[i]
        }
    }
}

extension GLKMatrix4 {
    var array: [Float] {
        return (0..<16).map { i in
            self[i]
        }
    }
}

extension Array {
    var bufferSize: size_t {
        return sizeof(Element) * self.count
    }
}

private func unsafeBufferOffset(size: size_t) -> UnsafePointer<Void> {
    return UnsafePointer(bitPattern: size)
}

final class GameViewController: GLKViewController {
    
    var program: GLuint = 0
    
    var modelViewProjectionMatrix: GLKMatrix4 = GLKMatrix4Identity
    var normalMatrix: GLKMatrix3 = GLKMatrix3Identity
    var rotation: Float = 0.0
    
    var vertexArray: GLuint = 0
    var vertexBuffer: GLuint = 0
    
    var context: EAGLContext? = nil
    var effect: GLKBaseEffect? = nil
    
    deinit {
        self.tearDownGL()
        
        if EAGLContext.currentContext() === self.context {
            EAGLContext.setCurrentContext(nil)
        }
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let context = EAGLContext(API: .OpenGLES2) {
            self.context = context
        } else {
            println("Failed to create ES context")
        }
        
        self.gameView.context = self.context
        self.gameView.drawableDepthFormat = .Format24
        
        self.setupGL()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        if self.isViewLoaded() && self.view.window == nil {
            self.view = nil
            
            self.tearDownGL()
            
            if EAGLContext.currentContext() === self.context {
                EAGLContext.setCurrentContext(nil)
            }
            self.context = nil
        }
    }
    
    // MARK: Helpers
    
    var gameView: GLKView {
        return self.view as! GLKView
    }
    
    func setupGL() {
        EAGLContext.setCurrentContext(self.context)
        
        self.loadShaders()
        
        self.effect = GLKBaseEffect()
        self.effect!.light0.enabled = GLboolean(GL_TRUE)
        self.effect!.light0.diffuseColor = GLKVector4Make(1.0, 0.4, 0.4, 1.0)
        
        glEnable(GLenum(GL_DEPTH_TEST))
        
        glGenVertexArraysOES(1, &vertexArray)
        glBindVertexArrayOES(vertexArray)
        
        glGenBuffers(1, &vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        
        glBufferData(GLenum(GL_ARRAY_BUFFER), gCubeVertexData.bufferSize, gCubeVertexData, GLenum(GL_STATIC_DRAW))
        
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.Position.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.Position.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 24, unsafeBufferOffset(0))
        
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.Normal.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.Normal.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 24, unsafeBufferOffset(12))
        
        glBindVertexArrayOES(0);
    }
    
    func tearDownGL() {
        EAGLContext.setCurrentContext(self.context)
        
        glDeleteBuffers(1, &self.vertexBuffer)
        glDeleteVertexArraysOES(1, &self.vertexArray)
        
        self.effect = nil
        
        if self.program != 0 {
            glDeleteProgram(self.program)
            self.program = 0
        }
    }
    
    // MARK: GLKViewController
    
    func update() {
        let aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height)
        let projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0), Float(aspect), 0.1, 100.0)
        
        self.effect?.transform.projectionMatrix = projectionMatrix
        
        var baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0, 0.0, -4.0)
        baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, self.rotation, 0.0, 1.0, 0.0)
        
        // Compute the model view matrix for the object rendered with GLKit
        var modelViewMatrix = GLKMatrix4MakeTranslation(0.0, 0.0, -1.5)
        modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, self.rotation, 1.0, 1.0, 1.0)
        modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix)
        
        self.effect?.transform.modelviewMatrix = modelViewMatrix
        
        // Compute the model view matrix for the object rendered with ES2
        modelViewMatrix = GLKMatrix4MakeTranslation(0.0, 0.0, 1.5)
        modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, self.rotation, 1.0, 1.0, 1.0)
        modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix)
        
        self.normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), nil)
        
        self.modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix)
        
        self.rotation += Float(self.timeSinceLastUpdate * 0.5)
    }
    
    override func glkView(view: GLKView, drawInRect rect: CGRect) {
        glClearColor(0.65, 0.65, 0.65, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
        
        glBindVertexArrayOES(vertexArray)
        
        // Render the object with GLKit
        self.effect?.prepareToDraw()
        
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 36)
        
        // Render the object again with ES2
        glUseProgram(program)
        
        glUniformMatrix4fv(gUniforms[.ModelViewProjectionMatrix]!, 1, GLboolean(GL_FALSE), self.modelViewProjectionMatrix.array)
        glUniformMatrix3fv(gUniforms[.NormalMatrix]!, 1, GLboolean(GL_FALSE), self.normalMatrix.array)
        
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 36)
    }
    
    // MARK: -  OpenGL ES 2 shader compilation
    
    func loadShaders() -> Bool {
        var vertShader: GLuint = 0
        var fragShader: GLuint = 0
        var vertShaderPathname: String
        var fragShaderPathname: String
        
        // Create shader program.
        self.program = glCreateProgram()
        
        // Create and compile vertex shader.
        vertShaderPathname = NSBundle.mainBundle().pathForResource("Shader", ofType: "vsh")!
        if !self.compileShader(&vertShader, type: GLenum(GL_VERTEX_SHADER), file: vertShaderPathname) {
            println("Failed to compile vertex shader")
            return false
        }
        
        // Create and compile fragment shader.
        fragShaderPathname = NSBundle.mainBundle().pathForResource("Shader", ofType: "fsh")!
        if !self.compileShader(&fragShader, type: GLenum(GL_FRAGMENT_SHADER), file: fragShaderPathname) {
            println("Failed to compile fragment shader");
            return false
        }
        
        // Attach vertex shader to program.
        glAttachShader(self.program, vertShader)
        
        // Attach fragment shader to program.
        glAttachShader(self.program, fragShader)
        
        // Bind attribute locations.
        // This needs to be done prior to linking.
        glBindAttribLocation(self.program, GLuint(GLKVertexAttrib.Position.rawValue), "position")
        glBindAttribLocation(self.program, GLuint(GLKVertexAttrib.Normal.rawValue), "normal")
        
        // Link program.
        if !self.linkProgram(self.program) {
            println("Failed to link program: \(self.program)")
            
            if vertShader != 0 {
                glDeleteShader(vertShader)
                vertShader = 0
            }
            if fragShader != 0 {
                glDeleteShader(fragShader)
                fragShader = 0
            }
            if self.program != 0 {
                glDeleteProgram(self.program)
                self.program = 0
            }
            
            return false
        }
        
        // Get uniform locations.
        gUniforms[.ModelViewProjectionMatrix] = glGetUniformLocation(self.program, "modelViewProjectionMatrix")
        gUniforms[.NormalMatrix] = glGetUniformLocation(self.program, "normalMatrix")
        
        // Release vertex and fragment shaders.
        if vertShader != 0 {
            glDetachShader(self.program, vertShader)
            glDeleteShader(vertShader);
        }
        if fragShader != 0 {
            glDetachShader(self.program, fragShader);
            glDeleteShader(fragShader);
        }
        
        return true
    }
    
    func compileShader(inout shader: GLuint, type: GLenum, file: String) -> Bool {
        var error: NSError?
        if let source = NSString(contentsOfFile: file, encoding: NSUTF8StringEncoding, error: &error)?.UTF8String {
            [source].withUnsafeBufferPointer { sourcePointersPointer -> Void in
                shader = glCreateShader(type)
                glShaderSource(shader, 1, sourcePointersPointer.baseAddress, nil)
                glCompileShader(shader)
            }
            
            #if DEBUG
                var logLength: GLint = 0
                glGetShaderiv(shader, GLenum(GL_INFO_LOG_LENGTH), &logLength)
                if 0 < logLength {
                var log = Array<GLchar>(count: Int(logLength), repeatedValue: 0)
                log.withUnsafeBufferPointer { logPointer -> Void in
                glGetShaderInfoLog(shader, logLength, &logLength, UnsafeMutablePointer(logPointer.baseAddress))
                NSLog("Shader compile log: \n%@", String(UTF8String: log)!)
                }
                }
            #endif
            
            var status: GLint = 0
            glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &status)
            if status == 0 {
                glDeleteShader(shader);
                return false
            }
        } else {
            println("Failed to load vertex shader")
            return false
        }
        
        return true
    }
    
    func linkProgram(prog: GLuint) -> Bool {
        glLinkProgram(prog)
        
        #if DEBUG
            var logLength: GLint = 0
            glGetProgramiv(prog, GLenum(GL_INFO_LOG_LENGTH), &logLength)
            if 0 < logLength {
            var log = Array<GLchar>(count: Int(logLength), repeatedValue: 0)
            log.withUnsafeBufferPointer { logPointer -> Void in
            glGetProgramInfoLog(prog, logLength, &logLength, UnsafeMutablePointer(logPointer.baseAddress))
            NSLog("Program link log: \n%@", String(UTF8String: log)!)
            }
            }
        #endif
        
        var status: GLint = 0
        glGetProgramiv(prog, GLenum(GL_LINK_STATUS), &status)
        if status == 0 {
            return false
        }
        
        return true
    }
    
    func validateProgram(prog: GLuint) -> Bool {
        #if DEBUG
            var logLength: GLint = 0
            glGetProgramiv(prog, GLenum(GL_INFO_LOG_LENGTH), &logLength)
            if 0 < logLength {
            var log = Array<GLchar>(count: Int(logLength), repeatedValue: 0)
            log.withUnsafeBufferPointer { logPointer -> Void in
            glGetProgramInfoLog(prog, logLength, &logLength, UnsafeMutablePointer(logPointer.baseAddress))
            NSLog("Program validate log: \n%@", String(UTF8String: log)!)
            }
            }
        #endif
        
        var status: GLint = 0
        glGetProgramiv(prog, GLenum(GL_VALIDATE_STATUS), &status)
        if status == 0 {
            return false
        }
        return true
    }
    
}

private let gCubeVertexData: [GLfloat] = [
    // Data layout for each line below is:
    // positionX, positionY, positionZ,     normalX, normalY, normalZ,
    0.5, -0.5, -0.5,        1.0, 0.0, 0.0,
    0.5, 0.5, -0.5,         1.0, 0.0, 0.0,
    0.5, -0.5, 0.5,         1.0, 0.0, 0.0,
    0.5, -0.5, 0.5,         1.0, 0.0, 0.0,
    0.5, 0.5, -0.5,         1.0, 0.0, 0.0,
    0.5, 0.5, 0.5,          1.0, 0.0, 0.0,
    
    0.5, 0.5, -0.5,         0.0, 1.0, 0.0,
    -0.5, 0.5, -0.5,        0.0, 1.0, 0.0,
    0.5, 0.5, 0.5,          0.0, 1.0, 0.0,
    0.5, 0.5, 0.5,          0.0, 1.0, 0.0,
    -0.5, 0.5, -0.5,        0.0, 1.0, 0.0,
    -0.5, 0.5, 0.5,         0.0, 1.0, 0.0,
    
    -0.5, 0.5, -0.5,        -1.0, 0.0, 0.0,
    -0.5, -0.5, -0.5,      -1.0, 0.0, 0.0,
    -0.5, 0.5, 0.5,         -1.0, 0.0, 0.0,
    -0.5, 0.5, 0.5,         -1.0, 0.0, 0.0,
    -0.5, -0.5, -0.5,      -1.0, 0.0, 0.0,
    -0.5, -0.5, 0.5,        -1.0, 0.0, 0.0,
    
    -0.5, -0.5, -0.5,      0.0, -1.0, 0.0,
    0.5, -0.5, -0.5,        0.0, -1.0, 0.0,
    -0.5, -0.5, 0.5,        0.0, -1.0, 0.0,
    -0.5, -0.5, 0.5,        0.0, -1.0, 0.0,
    0.5, -0.5, -0.5,        0.0, -1.0, 0.0,
    0.5, -0.5, 0.5,         0.0, -1.0, 0.0,
    
    0.5, 0.5, 0.5,          0.0, 0.0, 1.0,
    -0.5, 0.5, 0.5,         0.0, 0.0, 1.0,
    0.5, -0.5, 0.5,         0.0, 0.0, 1.0,
    0.5, -0.5, 0.5,         0.0, 0.0, 1.0,
    -0.5, 0.5, 0.5,         0.0, 0.0, 1.0,
    -0.5, -0.5, 0.5,        0.0, 0.0, 1.0,
    
    0.5, -0.5, -0.5,        0.0, 0.0, -1.0,
    -0.5, -0.5, -0.5,      0.0, 0.0, -1.0,
    0.5, 0.5, -0.5,         0.0, 0.0, -1.0,
    0.5, 0.5, -0.5,         0.0, 0.0, -1.0,
    -0.5, -0.5, -0.5,      0.0, 0.0, -1.0,
    -0.5, 0.5, -0.5,        0.0, 0.0, -1.0
]
