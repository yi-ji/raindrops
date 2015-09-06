import Foundation
import GLKit

class Camera {
  
    static let maxVerticalAngle: GLfloat = 89.0 //must be less than 90 to avoid gimbal lock

    private var _position: GLKVector3 = GLKVector3()
    private var _horizontalAngle: GLfloat = 0
    private var _verticalAngle: GLfloat = 0
    private var _fieldOfView: GLfloat = 55.0
    private var _nearPlane: GLfloat = 0.01
    private var _farPlane: GLfloat = 100.0
    private var _viewportAspectRatio: GLfloat = 1

    private func normalizeAngles() -> Void {
        
        self._horizontalAngle = _horizontalAngle % 360.0
        
        if self._horizontalAngle < 0.0 {
            self._horizontalAngle += 360.0
        }
        
        if self._verticalAngle > Camera.maxVerticalAngle {
            self._verticalAngle = Camera.maxVerticalAngle
        } else if self._verticalAngle < -Camera.maxVerticalAngle {
            self._verticalAngle = -Camera.maxVerticalAngle
        }
        
    }

    var position: GLKVector3 {
        get {
            return self._position
        }
    }
    
    var fieldOfView: GLfloat {
        get {
            return self._fieldOfView
        }
    }
    
    var nearPlane: GLfloat {
        get {
            return self._nearPlane
        }
    }
    
    var farPlane: GLfloat {
        get {
            return self._farPlane
        }
    }
    
    var viewportAspectRatio: GLfloat {
        get {
            return self._viewportAspectRatio
        }
    }
    
    var orientation: GLKMatrix4 {
        get {
            var _orientation = GLKMatrix4Identity
            _orientation = GLKMatrix4RotateWithVector3(_orientation, GLKMathDegreesToRadians(self._verticalAngle), GLKVector3Make(1, 0, 0))
            _orientation = GLKMatrix4RotateWithVector3(_orientation, GLKMathDegreesToRadians(self._horizontalAngle), GLKVector3Make(0, 1, 0))
            return _orientation
        }
    }
    
    var up: GLKVector3 {
        get {
            let _up = GLKMatrix4MultiplyVector4(self.orientation.invert, GLKVector4Make(0, 1, 0, 1))
            return GLKVector3Make(_up.x, _up.y, _up.z)
        }
    }
    
    var forward: GLKVector3 {
        get {
            let _forward = GLKMatrix4MultiplyVector4(self.orientation.invert, GLKVector4Make(0, 0, -1, 1))
            return GLKVector3Make(_forward.x, _forward.y, _forward.z)
        }
    }
    
    var right: GLKVector3 {
        get {
            let _right = GLKMatrix4MultiplyVector4(self.orientation.invert, GLKVector4Make(1, 0, 0, 1))
            return GLKVector3Make(_right.x, _right.y, _right.z)
        }
    }
    
    var view: GLKMatrix4 {
        get {
            return GLKMatrix4Multiply(self.orientation, GLKMatrix4TranslateWithVector3(GLKMatrix4Identity, GLKVector3Negate(self.position)))
        }
    }
    
    var projection: GLKMatrix4 {
        get {
            return GLKMatrix4MakePerspective(GLKMathDegreesToRadians(self.fieldOfView), self.viewportAspectRatio, self.nearPlane, self.farPlane)
        }
    }
    
    var matrix: GLKMatrix4 {
        get {
            return GLKMatrix4Multiply(self.projection, self.view)
        }
    }
    
    func offsetOrientation(let upAngle: GLfloat, let rightAngle: GLfloat) -> Void {
        self._horizontalAngle += rightAngle;
        self._verticalAngle += upAngle;
        self.normalizeAngles();
    }
    
    func lookAt(let lookAtPosition: GLKVector3) -> Void {
        if GLKVector3AllEqualToVector3(self.position, lookAtPosition) {
            NSLog("Look at position: %@, the camera position: %@", lookAtPosition.array, self._position.array)
            return
        }
        let direction: GLKVector3 = GLKVector3Normalize(GLKVector3Subtract(self.position, lookAtPosition))
        self._verticalAngle = GLKMathDegreesToRadians(asinf(-direction.y))
        self._horizontalAngle = -GLKMathDegreesToRadians(atan2f(-direction.x, -direction.z));
        normalizeAngles();
    }
    
    func setPosition(let position: GLKVector3) -> Void {
        self._position = position
    }
    
    func offsetPosition(let offset: GLKVector3) -> Void {
        self._position = GLKVector3Add(self._position, offset)
    }
    
    func setFieldOfView(let fieldOfView: GLfloat) -> Void {
        if fieldOfView > 0.0 && fieldOfView < 180 {
            self._fieldOfView = fieldOfView
        }
    }
    
    func setNearAndFarPlanes(let nearPlane: GLfloat, let farPlane: GLfloat) -> Void {
        if nearPlane < 0.0 || nearPlane > farPlane {
            NSLog("Bad nearPlane: %@ and farPlane: %@", nearPlane, farPlane)
        }
        self._nearPlane = nearPlane;
        self._farPlane = farPlane;
    }
    
    func setViewportAspectRatio(let viewportAspectRatio: GLfloat) -> Void {
        self._viewportAspectRatio = viewportAspectRatio
    }
}