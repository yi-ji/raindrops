import Foundation
import GLKit

class ShaderProgram {
 
    convenience init(vertexShaderFileName: String, fragmentShaderFileName: String) {
        self.init()
        self.loadShaders(vertexShaderFileName, fragmentShaderFileName)
    }
    
    deinit {
        if self.validateProgram() {
            self.stopUsingProgram()
            self.deleteProgram()
        }
    }
    
    private var _program: GLuint = 0

    // Shader attributes and uniforms indices
    var program: GLuint {
        get {
            return self._program
        }
    }
    func uniform(let uniformName: String) -> GLint {
        let uniformIndex = glGetUniformLocation(self._program, uniformName)
        if (uniformIndex == -1) {
            NSLog("Bad uniform name: \n%@", uniformName)
        }
        return uniformIndex
    }
    func attrib(let attribName: String) -> GLuint {
        let attribIndex = glGetAttribLocation(self._program, attribName)
        if (attribIndex == -1) {
            NSLog("Bad attribute name: \n%@", attribName)
        }
        return GLuint(attribIndex)
    }
    // Indices end
    
    // Attributes and uniforms setters
    func setUniform(let name: String, let _ value: GLint) -> Void {
        glUniform1i(self.uniform(name), value)
    }
    
    func setUniform(let name: String, let _ value: GLfloat) -> Void {
        glUniform1f(self.uniform(name), value)
    }
    
    func setUniform(let name: String, let _ matrix: GLKMatrix2, let _ transpose: GLboolean = GLboolean(GL_FALSE)) -> Void {
        glUniformMatrix2fv(self.uniform(name), 1, transpose, matrix.array)
    }
    
    func setUniform(let name: String, let _ matrix: GLKMatrix3, let _ transpose: GLboolean = GLboolean(GL_FALSE)) -> Void {
        glUniformMatrix3fv(self.uniform(name), 1, transpose, matrix.array)
    }
    
    func setUniform(let name: String, let _ matrix: GLKMatrix4, let _ transpose: GLboolean = GLboolean(GL_FALSE)) -> Void {
        glUniformMatrix4fv(self.uniform(name), 1, transpose, matrix.array)
    }
    
    func setUniform(let name: String, let _ vector: GLKVector2) -> Void {
        glUniform2fv(self.uniform(name), 1, vector.array)
    }
    
    func setUniform(let name: String, let _ vector: GLKVector3) -> Void {
        glUniform3fv(self.uniform(name), 1, vector.array)
    }
    
    func setUniform(let name: String, let _ vector: GLKVector4) -> Void {
        glUniform4fv(self.uniform(name), 1, vector.array)
    }
    
    func setAttrib(let name: String, let _ value: GLfloat) -> Void {
        glVertexAttrib1f(self.attrib(name), value)
    }
    
    func setAttrib(let name: String, let _ value: GLKVector2) -> Void {
        glVertexAttrib2fv(self.attrib(name), value.array)
    }
    
    func setAttrib(let name: String, let _ value: GLKVector3) -> Void {
        glVertexAttrib3fv(self.attrib(name), value.array)
    }
    
    func setAttrib(let name: String, let _ value: GLKVector4) -> Void {
        glVertexAttrib4fv(self.attrib(name), value.array)
    }
    // setters end
    
    // Program controllers
    func useProgram() -> Void {
        glUseProgram(self._program)
    }
    
    func stopUsingProgram() -> Void {
        if (self.isInUse()) {
            glUseProgram(0)
        }
    }
    
    func isInUse() -> Bool {
        var currentProgram: GLint = 0
        glGetIntegerv(GLenum(GL_CURRENT_PROGRAM), &currentProgram)
        return (currentProgram == GLint(self._program))
    }
   
    private func deleteProgram() -> Void {
        
        #if DEBUG
            NSLog("Delete program: \n%@", self.program)
        #endif
        
        glDeleteProgram(self._program)
        self._program = 0
    }
    
    private func linkProgram() -> Bool {
        glLinkProgram(self.program)
        
        #if DEBUG
            var logLength: GLint = 0
            glGetProgramiv(self.program, GLenum(GL_INFO_LOG_LENGTH), &logLength)
            if 0 < logLength {
            var log = Array<GLchar>(count: Int(logLength), repeatedValue: 0)
            log.withUnsafeBufferPointer { logPointer -> Void in
            glGetProgramInfoLog(self.program, logLength, &logLength, UnsafeMutablePointer(logPointer.baseAddress))
            NSLog("Program link log: \n%@", String(UTF8String: log)!)
            }
            }
        #endif
        
        var status: GLint = 0
        glGetProgramiv(self.program, GLenum(GL_LINK_STATUS), &status)
        if status == 0 {
            return false
        }
        
        return true
    }
    
    private func validateProgram() -> Bool {
        #if DEBUG
            var logLength: GLint = 0
            glGetProgramiv(program, GLenum(GL_INFO_LOG_LENGTH), &logLength)
            if 0 < logLength {
            var log = Array<GLchar>(count: Int(logLength), repeatedValue: 0)
            log.withUnsafeBufferPointer { logPointer -> Void in
            glGetProgramInfoLog(self.program, logLength, &logLength, UnsafeMutablePointer(logPointer.baseAddress))
            NSLog("Program validate log: \n%@", String(UTF8String: log)!)
            }
            }
        #endif
        
        var status: GLint = 0
        glGetProgramiv(self._program, GLenum(GL_VALIDATE_STATUS), &status)
        if status == 0 {
            return false
        }
        return true
    }
    // Program controllers end
    
    
    // Shader helpers
    private func compileShader(inout shader: GLuint, let type: GLenum, let file: String) -> Bool {
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
    
    func loadShaders(let vertextShaderFileName: String, let _ fragmentShaderFileName: String) -> Bool {
        
        self._program = glCreateProgram()
        var vertShader: GLuint = 0
        var fragShader: GLuint = 0
        var vertShaderPathname: String
        var fragShaderPathname: String
        
        
        // Create and compile vertex shader.
        vertShaderPathname = NSBundle.mainBundle().pathForResource(vertextShaderFileName, ofType: "vsh")!
        if !self.compileShader(&vertShader, type: GLenum(GL_VERTEX_SHADER), file: vertShaderPathname) {
            println("Failed to compile vertex shader")
            return false
        }
        
        // Create and compile fragment shader.
        fragShaderPathname = NSBundle.mainBundle().pathForResource(fragmentShaderFileName, ofType: "fsh")!
        if !self.compileShader(&fragShader, type: GLenum(GL_FRAGMENT_SHADER), file: fragShaderPathname) {
            println("Failed to compile fragment shader");
            return false
        }
        
        // Attach vertex shader to program.
        glAttachShader(self._program, vertShader)
        
        // Attach fragment shader to program.
        glAttachShader(self._program, fragShader)
        
        // Link program.
        if !self.linkProgram() {
            println("Failed to link program: \(self._program)")
            
            if vertShader != 0 {
                glDeleteShader(vertShader)
                vertShader = 0
            }
            if fragShader != 0 {
                glDeleteShader(fragShader)
                fragShader = 0
            }
            if self._program != 0 {
                glDeleteProgram(self._program)
                self._program = 0
            }
            
            return false
        }
        
        // Release vertex and fragment shaders.
        if vertShader != 0 {
            glDetachShader(self._program, vertShader)
            glDeleteShader(vertShader);
        }
        if fragShader != 0 {
            glDetachShader(self._program, fragShader);
            glDeleteShader(fragShader);
        }
        
        return true
    }
    // Shader helpers end
}