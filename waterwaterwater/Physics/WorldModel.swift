//
//  WorldModel.swift
//  waterwaterwater
//
//  Created by 郝有峰 on 15/5/8.
//  Copyright (c) 2015年 郝有峰. All rights reserved.
//

import Foundation
import GLKit

class WorldModel {
    
    private var _failed: Bool = false {
        didSet {
            if self._failed == true {
                //println("Failed")
                self._stains.removeAll()
                self._droplets.removeAll()
            }
        }
    }
    var failed: Bool {
        get {
            return self._failed
        }
    }
    
    private var _time: NSTimeInterval = 0.0
    var time: NSTimeInterval {
        get {
            return self._time
        }
    }
    private var _gravityAcc: GLKVector3 = GLKVector3()
    var gravityAcc: GLKVector3 {
        get {
            return self._gravityAcc
        }
        set {
            self._gravityAcc = newValue
        }
    }
    
    // 零号水滴代表"自己"
    private var _droplets = [Int: DropletModel]()
    private var _dropletMax: Int = 0 //倒排是为了让后出现的先画,不被覆盖
    var droplets: [Int: DropletModel] {
        get {
            return self._droplets
        }
    }
    
    // 水痕
    private var _stains = [Int: StainModel]()
    private var _stainsMax = 0
    var stains: [Int: StainModel] {
        get {
            return self._stains
        }
    }

    private struct Constants {
        static let staticWaterGlassFraction = GLfloat(1.0 / 100.0)
        static let dynamicWaterGlassFraction = GLfloat(1.0 / 300.0)
        static let twoWaterMinRadius = GLfloat(0.02)
        static let twoWaterAttract = GLfloat(0.001)
    }
    
    func addDroplet(let position: GLKVector3, let _ radius: GLfloat, let vel: GLKVector3 = GLKVector3Make(0, 0, 0), let colorEnum: DropletColor = .None) {
        let color = DropletModel.getColor(colorEnum)
        var newDroplet = DropletModel(position, GLKVector3Make(0, 0, 0), vel, radius, bornTime: self._time, initID: self._dropletMax, _color: color)
        self._dropletMax += 1
        newDroplet.delegate = self
        newDroplet.colorEnum = colorEnum
        self._droplets[newDroplet.ID] = newDroplet
    }
    
    func addStain(let droplet: DropletModel) {
        var newStain = StainModel(droplet: droplet, bornTime: self._time, initID: _stainsMax)
        _stainsMax += 1
        newStain.delegate = self
        newStain.color = GLKVector4MultiplyScalar(droplet.color, 0.3)
        self._stains[newStain.ID] = newStain
    }
    
    func reset() {
        self._droplets.removeAll(keepCapacity: false)
        self._stains.removeAll(keepCapacity: false)
        self._failed = false
        self._time = 0
        self.lastAddTime = 0
        self._stainsMax = 0
        self._dropletMax = 0
    }
    
    func timeFlee(let time: NSTimeInterval) {
        self._time += time
        self.addPeriodDroplet()
        //println("World update at \(self._time)s")
        
        for (ID, stain) in self.stains {
            stain.applyChange(time)
        }
        
        let maxBounds = GLKVector3Length(bounds[0])
        for (ID, droplet) in self.droplets {
            //println("gravityAcc \(self.gravityAcc.array), mass \(droplet.mass)")
            
            // 超出屏幕范围的消失
            let positionLen = GLKVector3Length(droplet.position)
            if (positionLen > maxBounds + 0.1) {
                self.removeDroplet(droplet)
                continue
            }
            
            // 重力
            var gravity = (GLKVector3MultiplyScalar(self.gravityAcc, droplet.mass))
            var force = [gravity]
            
            // 摩擦力
            var fraction = droplet.velocity
            var velLen = GLKVector3Length(droplet.velocity)
            if (velLen > 0) {
                fraction = GLKVector3Normalize(fraction)
            }
            if (velLen < PhysicsModel.Constants.minVelocity) {
                fraction = GLKVector3MultiplyScalar(fraction, -droplet.mass * Constants.staticWaterGlassFraction)
            } else {
                fraction = GLKVector3MultiplyScalar(fraction, -droplet.mass * Constants.dynamicWaterGlassFraction)
            }
            force += [fraction]
            
            //其他水滴的引力
            var attractForce = GLKVector3Make(0, 0, 0)
            for (ID2, droplet2) in self.droplets {
                if (ID == ID2) {
                    continue
                }
                
                let vec = GLKVector3Subtract(droplet2.position, droplet.position)
                let dis = GLKVector3Length(vec)
                
                // 判断相交
                if (dis > droplet.radius * cos(droplet.contactAngle) + droplet2.radius * cos(droplet2.contactAngle)) {
                    continue
                }
                let droplet1Curve = MathUtils.dropletEdgeCurve(droplet)
                let droplet2Curve = MathUtils.dropletEdgeCurve(droplet2)
                let intersect = MathUtils.curveIntersect((droplet.position, droplet1Curve), secondCurve: (droplet2.position, droplet2Curve))
                if (!intersect) {
                    continue
                }
                // 不同颜色水滴相交,判断已失败
                if (droplet.colorEnum != droplet2.colorEnum) {
                    self._failed = true
                    return
                }
                
                attractForce = GLKVector3Add(attractForce,
                    GLKVector3MultiplyScalar(vec, (droplet.radius + droplet2.radius) * Constants.twoWaterAttract / dis))
                //println("\(ID) \(ID2)   \(attractForce.array)")
                
            }
            force += [attractForce]

            
            droplet.applyChange(time, force)
            self.addStain(droplet)
        }
        
        // 合并水滴
        for (ID1, droplet1) in self.droplets {
            for (ID2, droplet2) in self.droplets {
                if (ID1 == ID2) {
                    continue
                }
                let dis = GLKVector3Length(GLKVector3Subtract(droplet1.position, droplet2.position))
                if (dis < Constants.twoWaterMinRadius) {
                    let newMass = droplet1.mass + droplet2.mass
                    let pos1 = GLKVector3MultiplyScalar(droplet1.position, droplet1.mass)
                    let pos2 = GLKVector3MultiplyScalar(droplet2.position, droplet2.mass)
                    let newPosition = GLKVector3DivideScalar(GLKVector3Add(pos1, pos2), newMass)
                    let newRadius = powf(powf(droplet1.radius, 3.0) + powf(droplet2.radius, 3.0), 1.0 / 3.0)
                    let p1 = GLKVector3MultiplyScalar(droplet1.velocity, droplet1.mass)
                    let p2 = GLKVector3MultiplyScalar(droplet2.velocity, droplet2.mass)
                    let newV = GLKVector3DivideScalar(GLKVector3Add(p1, p2), newMass)
                    self.addDroplet(newPosition, newRadius, vel: newV, colorEnum: droplet1.colorEnum)
//                    println("\(droplet1.velocity.array) \(droplet2.velocity.array)")
//                    println("fuse \(p1.array) \(p2.array) \(newV.array) \(newMass)")
                    self.removeDroplet(droplet1)
                    self.removeDroplet(droplet2)
                }
                
            }
        }
        
    }
    
    // 视线内的四角,左上右上右下左下
    var bounds: [GLKVector3] = [GLKVector3Make(0, 0, 0), GLKVector3Make(0, 0, 0), GLKVector3Make(0, 0, 0), GLKVector3Make(0, 0, 0)]
    // 按周期随机添加水滴
    var lastAddTime: NSTimeInterval = 0.0
    func addPeriodDroplet() {
        let period = 0.5
        let t = self._time - lastAddTime - period
        if (t > 0) {
            // 从哪个角添加, 目前默认上方
            let whichCorner = 0
            var position: GLKVector3?
            var velocity: GLKVector3?
            var radius: GLfloat = GLfloat(random()) / GLfloat(RAND_MAX) * (0.04 - 0.01) + 0.01
            switch whichCorner {
            case 0:
                let positionX = bounds[0].x + (bounds[1].x - bounds[0].x) * GLfloat(random()) / GLfloat(RAND_MAX)
                let positionY = bounds[0].y
                position = GLKVector3Make(positionX, positionY, 0.0)
            case 1:
                let positionX = bounds[1].x
                let positionY = bounds[2].y + (bounds[1].y - bounds[2].y) * GLfloat(random()) / GLfloat(RAND_MAX)
                position = GLKVector3Make(positionX, positionY, 0.0)
            case 2:
                let positionX = bounds[3].x + (bounds[2].x - bounds[3].x) * GLfloat(random()) / GLfloat(RAND_MAX)
                let positionY = bounds[2].y
                position = GLKVector3Make(positionX, positionY, 0.0)
            case 3:
                let positionX = bounds[3].x
                let positionY = bounds[3].y + (bounds[0].y - bounds[3].y) * GLfloat(random()) / GLfloat(RAND_MAX)
                position = GLKVector3Make(positionX, positionY, 0.0)
            default: break
            }
            velocity = GLKVector3Negate(position!)
            velocity = GLKVector3Normalize(velocity!)
            velocity = GLKVector3MultiplyScalar(velocity!, sqrt(DropletModel.Constants.maxVel))
            // 30%概率出现红色
            let randomColor = GLfloat(random() % 100) / GLfloat(100)
            var colorEnum = DropletColor.None
            if (randomColor < 0.2) {
                colorEnum = DropletColor.Purple
            }
            self.addDroplet(position!, radius, vel: velocity!, colorEnum: colorEnum)
            lastAddTime = self._time
        }
    }
    
    func removeDroplet(var droplet: DropletModel) {
        self._droplets.removeValueForKey(droplet.ID)
    }
    
    func removeStain(var stain: StainModel) {
        self._stains.removeValueForKey(stain.ID)
    }
}