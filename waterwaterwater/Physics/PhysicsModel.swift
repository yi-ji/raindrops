//
//  PhysicsModel.swift
//  waterwaterwater
//
//  Created by 郝有峰 on 15/5/9.
//  Copyright (c) 2015年 郝有峰. All rights reserved.
//

import Foundation
import GLKit

protocol PhysicsObject {
    var velocity: GLKVector3 { get }
    var acceleration: GLKVector3 { get }
    var position: GLKVector3 { get }
    var mass: GLfloat { get }
    var description: String { get }
}

enum DropletColor {
    case Red
    case Purple
    case None
}

class PhysicsModel {
    
    private var _velocity: GLKVector3 = GLKVector3Make(0, 0, 0)
    private var _acceleration: GLKVector3 = GLKVector3Make(0, 0, 0)
    private var _position: GLKVector3 = GLKVector3Make(0, 0, 0)
    private var _mass: GLfloat = 1.0
    
    weak var delegate: WorldModel?
    
    let ID: Int
    let bornTime: NSTimeInterval
    
    var velocity: GLKVector3 {
        get {
            return self._velocity
        }
    }
    
    private var _previousAcce = GLKVector3Make(0, 0, 0)
    var previousAcce: GLKVector3 {
        get {
            return self._previousAcce
        }
    }
    
    private var _previousVel = GLKVector3Make(0, 0, 0)
    var previousVel: GLKVector3 {
        get {
            return self._previousVel
        }
    }
    
    var acceleration: GLKVector3 {
        get {
            return self._acceleration
        }
    }
    
    var position: GLKVector3 {
        get {
            return self._position
        }
    }
    
    var mass: GLfloat {
        get {
            return self._mass
        }
    }
    
    struct Constants {
        static let minVelocity: GLfloat = 0.0005
        static let minAcceleration: GLfloat = 0.0005
    }
    
    init(let _ initPosition: GLKVector3, let _ initVelocity: GLKVector3, let _ initAcceleration: GLKVector3, let _ bornTime: NSTimeInterval, let _ initID: Int) {
        self._velocity = initVelocity
        self._acceleration = initAcceleration
        self._position = initPosition
        self.ID = initID
        self.bornTime = bornTime
    }
    
    
    func applyChange(let timeSinceLastUpdate: NSTimeInterval, let _ forces: [GLKVector3]) -> Void {
        let floatTime = Float(timeSinceLastUpdate)
        //println("Position: \(self._position.array)")
        //println("floatTime: \(floatTime)")
        //println("Velocity: \(self._velocity.array)")
        //println("Acceleration: \(self._acceleration.array)")
        self._position = GLKVector3Add(self._position, GLKVector3MultiplyScalar(self._velocity, floatTime))
        
        let velLength = GLKVector3Length(self._velocity)
        if (velLength > Constants.minVelocity) {
            self._previousVel = self.velocity
        }
        self._velocity = GLKVector3Add(self._velocity, GLKVector3MultiplyScalar(self._acceleration, floatTime))

        self._previousAcce = self.acceleration
        self._acceleration = GLKVector3Make(0, 0, 0)
        
        // 第一个是重力, 静止状态下, 其他力合力不大于重力
        let gravityAcc = GLKVector3DivideScalar(forces[0], self._mass)
        
        // 阻力
        var fractionAcc = GLKVector3DivideScalar(forces[1], self._mass)
        if (velLength < Constants.minVelocity) {
            if (GLKVector3Length(fractionAcc) > GLKVector3Length(gravityAcc)) {
                fractionAcc = GLKVector3Negate(gravityAcc)
            }
        }
        self._acceleration = GLKVector3Add(gravityAcc, fractionAcc)
        
        // 引力
        let attractAcc = GLKVector3DivideScalar(forces[2], self._mass)
        self._acceleration = GLKVector3Add(self._acceleration, attractAcc)
        //self._acceleration = GLKVector3Add(,GLKVector3Make(PhysicsModel._gravityAcc.x,PhysicsModel._gravityAcc.y,0))
    }
    
}

class DropletModel: PhysicsModel, PhysicsObject {
    
    static func getColor(colorEnum: DropletColor) -> GLKVector4 {
        switch colorEnum {
        case .Red:
            return GLKVector4Make(1.0, 0, 0, 0)
        case .Purple:
            return GLKVector4Make(0.5, 0.0, 0.5, 0.0)
        case .None:
            return GLKVector4Make(0, 0, 0, 0)
        }
    }
    
    var description: String {
        get {
            return "DropletModel: { \n\t position: \(self.position) \n\t velocity: \(self.velocity) \n\t radius: \(self.radius)"
        }
    }
    
    var color = GLKVector4Make(0, 0, 0, 0)
    
    struct Constants {
        static let evaporationEffcient: GLfloat = 0.001
        static let maxVel: GLfloat = 0.5
        static let minRadius: GLfloat = 0.005
    }
    
    func maxVelByRadius() -> GLfloat {
        let ratio = min(self.radius / 0.08, 1.0)
        return Constants.maxVel * ratio
    }
    
    override func applyChange(timeSinceLastUpdate: NSTimeInterval, _ forces: [GLKVector3]) {
        super.applyChange(timeSinceLastUpdate, forces)
        self.radius -= Constants.evaporationEffcient * GLfloat(timeSinceLastUpdate)
        var nowVel = GLKVector3Length(self.velocity)
        let nowAcc = super.acceleration
        let maxV = self.maxVelByRadius()
        if (nowVel > maxV) {
            let ratio = sqrt(maxV / nowVel)
            self._velocity = GLKVector3MultiplyScalar(self._velocity, ratio)
        }
        if (self.radius < Constants.minRadius) {
            self.delegate?.removeDroplet(self)
        }
    }
    
    private var _radius: GLfloat = 1
    
    private var _perimeter: GLfloat = 1
    var perimeter: GLfloat {
        get {
            return self._perimeter
        }
    }
    
    private var _area: GLfloat = 1
    
    var area: GLfloat {
        get {
            return self._area
        }
    }
    
    private var _contactAngle: GLfloat = GLfloat(M_PI) * 1.0 / 6 // radian
    
    var contactAngle: GLfloat {
        get {
            return self._contactAngle
        }
    }
    
    var interpolateVars = [[GLfloat]]()
    var radius: GLfloat {
        get {
            return self._radius
        }
        set {
            self._radius = newValue
            self._area = GLfloat(M_PI) * pow((newValue * cos(self._contactAngle)), 2)
            self._mass = pow(newValue, 3) * GLfloat(M_PI) * 3 / 2
            self._perimeter = newValue * cos(self._contactAngle) * 2 * GLfloat(M_PI)
        }
    }
    
    var colorEnum: DropletColor = DropletColor.None
    init(let _ initPosition: GLKVector3, let _ initVelocity: GLKVector3,
        let _ initAcceleration: GLKVector3, let _ radius: GLfloat, let _ contaceAngle: GLfloat = GLfloat(M_PI) / 4, let bornTime: NSTimeInterval, let initID: Int, let _color: GLKVector4 = GLKVector4Make(0, 0, 0, 1)) {
        let initIDString = initID
        super.init(initPosition, initVelocity, initAcceleration, bornTime, initIDString)
        self.interpolateVars = MathUtils.getSimpsonCurve()
        self._contactAngle = contaceAngle
        self.radius = radius
        self.color = _color
    }
}


class StainModel: PhysicsModel, PhysicsObject {
    
    var _stainAsset: ModelAsset?
    var stainAsset: ModelAsset {
        get {
            return self._stainAsset!
        }
    }
    
    var color = GLKVector4Make(0, 0, 0, 0)
    
    var description: String {
        get {
            return "Stain: { \n\t position: \(self.position) \n\t velocity: \(self.velocity) \n\t radius: \(self.radius)"
        }
    }
    
    func applyChange(timeSinceLastUpdate: NSTimeInterval) {
        self._ratio -= Constants.evaporationEffcient * GLfloat(timeSinceLastUpdate)
        if (self._ratio < Constants.minRatio) {
            self.delegate?.removeStain(self)
        }
    }
    
    private struct Constants {
        static let evaporationEffcient: GLfloat = 0.3
        static let minRatio: GLfloat = 0.05
    }
    
    
    private var _ratio: GLfloat = 1.0
    var ratio: GLfloat {
        get {
            return self._ratio
        }
    }
    
    private var _radius: GLfloat = 1
    
    private var _perimeter: GLfloat = 1
    var perimeter: GLfloat {
        get {
            return self._perimeter
        }
    }
    
    private var _area: GLfloat = 1
    
    var area: GLfloat {
        get {
            return self._area
        }
    }
    
    private var _contactAngle: GLfloat = GLfloat(M_PI) * 1 / 3.0 // radian
    
    var contactAngle: GLfloat {
        get {
            return self._contactAngle
        }
    }
    
    var interpolateVars = [[GLfloat]]()
    var radius: GLfloat {
        get {
            return self._radius
        }
        set {
            self._radius = newValue
        }
    }
    
    init(let droplet: DropletModel, let bornTime: NSTimeInterval, let initID: Int) {
        let initIDString = initID
        super.init(droplet.position, GLKVector3Make(0, 0, 0), GLKVector3Make(0, 0, 0), bornTime, initIDString)
        self._stainAsset = ModelAssetLoader.stainAssetLoader(droplet)
    }

    var transform: GLKMatrix4 {
        get {
            let scale = GLKMatrix4MakeScale(self._ratio, self._ratio, 1)
            let translate = GLKMatrix4MakeTranslation(self.position.x, self.position.y, self.position.z)
            return GLKMatrix4Multiply(translate, scale)
        }
    }
}