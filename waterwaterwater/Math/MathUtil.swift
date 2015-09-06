import Foundation
import GLKit

class MathUtils
{
    static let pi: Float = Float(M_PI)
    static let wavy: Float = 1.5
    
    static func getRandomY(y:Float,lower:Float,upper:Float) -> Float
    {
        let ratio = GLfloat(arc4random()) / GLfloat(UINT32_MAX)
        return lower + (upper - lower) * ratio
    }
    
    static func getSimpsonCurve(N:Int = 10, lowerBound:Float = 0.8, upperBound:Float = 1.0) -> [[Float]]
    {
        var x:[Float] = Array(count: N+1, repeatedValue: 0.0)
        var h:[Float] = Array(count: N+1, repeatedValue: 0.0)
        var a:[Float] = Array(count: N+1, repeatedValue: 0.0)
        var b:[Float] = Array(count: N+1, repeatedValue: 0.0)
        var c:[Float] = Array(count: N+1, repeatedValue: 0.0)
        var d:[Float] = Array(count: N+1, repeatedValue: 0.0)
        var alpha:[Float] = Array(count: N+1, repeatedValue: 0.0)
        var l:[Float] = Array(count: N+1, repeatedValue: 1.0)
        var u:[Float] = Array(count: N+1, repeatedValue: 0.0)
        var z:[Float] = Array(count: N+1, repeatedValue: 0.0)
        
        a[0] = (lowerBound+upperBound)/2.0
        
        for i in 0...N
        {
            x[i] = pi * (Float(2*i) / Float(N))
            if (i != 0) {a[i] = getRandomY(a[i-1],lower:lowerBound,upper:upperBound)}
        }
        
        a[N] = a[0]
        a[N-1] = (a[N-2]+a[N])/2
    
        
        for i in 0...N-1
        {
            h[i] = x[i+1]-x[i]
        }
        
        
        for i in 1...N-1
        {
            alpha[i] = 3.0*(a[i+1]-a[i])/h[i] - 3.0*(a[i]-a[i-1])/h[i-1]
        }
        
        for i in 1...N-1
        {
            l[i] = 2.0*(x[i+1]-x[i-1])-h[i-1]*u[i-1]
            u[i] = h[i]/l[i]
            z[i] = (alpha[i]-h[i-1]*z[i-1])/l[i]
        }
        
        l[N] = 1
        z[N] = 0
        c[N] = 0
        
        for var j=N-1;j>=0;j--
        {
            c[j] = z[j]-u[j]*c[j+1]
            b[j] = (a[j+1]-a[j])/h[j] - h[j]*(c[j+1]+2.0*c[j])/3.0
            d[j] = (c[j+1]-c[j]) / (3.0*h[j])
        }
        
        
        var result:[[Float]] = Array(count: N, repeatedValue: [0.0,0.0,0.0,0.0])
        for i in 0...N-1
        {
            result[i] = [a[i],b[i],c[i],d[i]]
        }
        
        return result
    }
    
    
    static func dropletEdgeCurve(droplet: DropletModel) -> ((GLfloat) -> GLfloat) {
        let fnum: GLfloat = GLfloat(droplet.interpolateVars.count)
        let interpolate = droplet.interpolateVars
        let maxV: GLfloat = 0.3
        let vel = droplet.velocity
        let velLen: GLfloat = min(GLKVector3Length(vel), maxV)
        let p = -0.7 + (0.70 - 0.60) * velLen / maxV
        let m = 0.05 + (0.2 - 0.05) * velLen / maxV
        let q = 0.7 + (1.0 - 0.7) * velLen / maxV
        var vecRad: GLfloat = atan2(vel.y, vel.x)
        let radius = droplet.radius * cos(droplet.contactAngle)
        if (vecRad < 0.0) {
            vecRad += GLfloat(2.0 * M_PI)
        }
        if (vel.x != 0.0 || vel.y != 0.0) {
            vecRad = -(vecRad - 3.0 * GLfloat(M_PI) / 2.0)
        } else {
            vecRad = 0.0
        }
        let noise = {
            (let rad: GLfloat) -> GLfloat in
            let j = Int(floor(rad * fnum / (2.0 * GLfloat(M_PI))))
            let xj = GLfloat(j) * 2.0 * GLfloat(M_PI) / fnum
            let a = interpolate[j][0]
            let b = interpolate[j][1]
            let c = interpolate[j][2]
            let d = interpolate[j][3]
            let t = rad - xj
            return a + b * t + c * pow(t, 2.0) + d * pow(t, 3.0)
        }
        return {
            (var rad: GLfloat) -> GLfloat in
            let noiseDeform: GLfloat = noise(rad)
            rad += vecRad
            rad += ceil(-rad / (2.0 * GLfloat(M_PI))) * 2.0 * GLfloat(M_PI)
            let dropletShape: GLfloat = sqrt(pow(abs(p*cos(rad) + m*sin(rad)*cos(rad)), 2.0) + pow(abs(q*sin(rad)), 2.0))
            return  radius * dropletShape * noiseDeform
        }
    }
    
    static func getTriangles(polar: ((GLfloat) -> GLfloat), N: Int = 100) -> [GLfloat]
    {
        var theta:GLfloat = 0
        var result:[GLfloat] = Array(count: 3*(N+1), repeatedValue: 0.0)
        var counter:Int = 0
        let position = GLKVector3Make(0, 0, 0)
        result[counter++] = position.x
        result[counter++] = position.y
        result[counter++] = position.z
        for i in 1...N
        {
            result[counter++] = position.x + polar(theta)*cos(theta)
            result[counter++] = position.y + polar(theta)*sin(theta)
            result[counter++] = position.z
            theta += GLfloat(2.0 * M_PI)/GLfloat(N)
        }
        return result
    }
    
    static func curveIntersect(firstCurve:(position: GLKVector3, polar: (GLfloat) -> GLfloat),secondCurve: (position: GLKVector3, polar: (GLfloat) -> GLfloat)) -> Bool
    {
        var theta:GLfloat = atan2(firstCurve.position.y-secondCurve.position.y, firstCurve.position.x-secondCurve.position.x)
        var dist:GLfloat = GLKVector3Distance(firstCurve.position,secondCurve.position)
        var temp:GLfloat
        if (theta < 0)
        {
            theta += 2 * GLfloat(M_PI)
            temp = firstCurve.polar(theta) + secondCurve.polar(theta - GLfloat(M_PI))
        }
        else
        {
            temp = firstCurve.polar(theta) + secondCurve.polar(GLfloat(M_PI)+theta)
            
        }
        if (temp > dist)
        {
            return true;
        }
        return false;
    }
}



