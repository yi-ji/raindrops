import GLKit

extension GLKVector2 {
    var array: [Float] {
        return (0..<2).map { i in
            self[i]
        }
    }
}


extension GLKVector3 {
    var array: [Float] {
        return (0..<3).map { i in
            self[i]
        }
    }
}

extension GLKVector4 {
    var array: [Float] {
        return (0..<4).map { i in
            self[i]
        }
    }
    var toGLKVector3: GLKVector3 {
        return GLKVector3Make(self.x, self.y, self.z)
    }
}

extension GLKMatrix3 {
    var array: [Float] {
        return (0..<9).map { i in
            self[i]
        }
    }
    var invert: GLKMatrix3 {
        get {
            var invertible: Bool = true
            let invertedMatrix = GLKMatrix3Invert(self, &invertible)
            if invertible {
                return invertedMatrix
            } else {
                NSLog("The matrix: %@ is not invertible", self.array)
                return GLKMatrix3()
            }
        }
    }
}

extension GLKMatrix2 {
    var array: [Float] {
        return (0..<4).map { i in
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
    var invert: GLKMatrix4 {
        get {
            var invertible: Bool = true
            let invertedMatrix = GLKMatrix4Invert(self, &invertible)
            if invertible {
                return invertedMatrix
            } else {
                NSLog("The matrix: %@ is not invertible", self.array)
                return GLKMatrix4()
            }
        }
    }
}


extension Array {
    var bufferSize: size_t {
        return sizeof(Element) * self.count
    }
}

func unsafeBufferOffset(size: size_t) -> UnsafePointer<Void> {
    return UnsafePointer(bitPattern: size)
}