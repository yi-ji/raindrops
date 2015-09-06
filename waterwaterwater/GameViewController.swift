import GLKit
import CoreMotion


final class DropletGameViewController: GLKViewController {
    
    let worldModel = WorldModel()
    let render = Render()
    
    let motionManager = CMMotionManager()
    
    var context: EAGLContext? = nil
    
    var error: NSError?
    
    deinit {
        self.tearDownGL()
        
        motionManager.stopGyroUpdates()
        if EAGLContext.currentContext() === self.context {
            EAGLContext.setCurrentContext(nil)
        }
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if motionManager.deviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.05
            motionManager.startDeviceMotionUpdatesToQueue(NSOperationQueue.mainQueue()) {
                [weak self] (data: CMDeviceMotion!, error: NSError!) in
                
                self!.worldModel.gravityAcc =
                    GLKVector3DivideScalar(GLKVector3Make(GLfloat(data.gravity.x), GLfloat(data.gravity.y), 0), 10)
            }
        }
        
        if let context = EAGLContext(API: .OpenGLES2) {
            self.context = context
        } else {
            println("Failed to create ES context")
        }
        self.gameView.context = self.context
        self.gameView.drawableDepthFormat = .Format24
        // 抗锯齿选项
        // self.gameView.drawableMultisample = GLKViewDrawableMultisample.Multisample4X
        self.setupGL()
        
        self.preferredFramesPerSecond = 30;
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
        
        glEnable(GLenum(GL_DEPTH_TEST))
        glDepthFunc(GLenum(GL_LESS))
//        glEnable(GLenum(GL_BLEND))
//        glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA))

//        self.worldModel.addDroplet(GLKVector3Make(0.10, 0.15, 0), 0.05)
//        self.worldModel.addDroplet(GLKVector3Make(0.10, 0.19, 0), 0.06, colorEnum: DropletColor.Purple)
//        self.worldModel.addDroplet(GLKVector3Make(0.10, -0.10, 0), 0.02)
//        self.worldModel.addDroplet(GLKVector3Make(0.10, -0.20, 0), 0.03)
//        self.worldModel.addDroplet(GLKVector3Make(-0.10, 0.19, 0), 0.03)
//        self.worldModel.addDroplet(GLKVector3Make(-0.10, 0.10, 0), 0.04)
//        self.worldModel.addDroplet(GLKVector3Make(-0.10, -0.10, 0), 0.02)
//        self.worldModel.addDroplet(GLKVector3Make(-0.10, -0.15, 0), 0.03)
//        self.worldModel.addDroplet(GLKVector3Make(0.05, 0.15, 0), 0.03)
//        self.worldModel.addDroplet(GLKVector3Make(0.05, 0.19, 0), 0.04, colorEnum: DropletColor.Purple)
//        self.worldModel.addDroplet(GLKVector3Make(0.05, -0.10, 0), 0.02)
//        self.worldModel.addDroplet(GLKVector3Make(0.05, -0.20, 0), 0.03)
//        self.worldModel.addDroplet(GLKVector3Make(-0.05, 0.19, 0), 0.03)
//        self.worldModel.addDroplet(GLKVector3Make(-0.05, 0.10, 0), 0.04)
//        self.worldModel.addDroplet(GLKVector3Make(-0.05, -0.10, 0), 0.02)
//        self.worldModel.addDroplet(GLKVector3Make(-0.05, -0.15, 0), 0.03)
        
    }
    
    func tearDownGL() {
        EAGLContext.setCurrentContext(self.context)
    }
    
    // MARK: GLKViewController
    
    func update() {
        let aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height)
        self.render.camera.setViewportAspectRatio(GLfloat(aspect))
        
        
        let h: GLfloat = 0.9 * tan(GLKMathDegreesToRadians(self.render.camera.fieldOfView) / 2)
        let w = h * GLfloat(aspect)
        self.worldModel.bounds[0] = GLKVector3Make(-w, h, 0)
        self.worldModel.bounds[1] = GLKVector3Make(w, h, 0)
        self.worldModel.bounds[2] = GLKVector3Make(w, -h, 0)
        self.worldModel.bounds[3] = GLKVector3Make(-w, -h, 0)

        let cameraPos = GLKVector3Make(0, 0, 0.9)
        self.render.camera.setPosition(cameraPos)
        self.worldModel.timeFlee(timeSinceLastUpdate)
        
        if (self.worldModel.failed == true) {
            self.paused = true
            let alertMessage = String(format: "You stayed for %.2f seconds!:P", self.worldModel.time)
            let alertController = UIAlertController(title: nil, message: alertMessage,
                preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Restart", style: UIAlertActionStyle.Default,
                handler: {
                    action -> Void in
                    self.paused = false
                    self.worldModel.reset()
            }))
            self.presentViewController(alertController, animated: true, completion: nil)
        }
        
        if !motionManager.deviceMotionAvailable {
            if (timeSinceFirstResume < 10.0) {
                self.worldModel.gravityAcc = GLKVector3Make(0.0, -0.003 * GLfloat(timeSinceFirstResume), 0.0)
            }
            else {
                let t = GLfloat(timeSinceFirstResume - 10) / 2.0
                self.worldModel.gravityAcc = GLKVector3Make(0.015 * cos(t), -0.03, 0.0)
            }
        }
    }
    
    override func glkView(view: GLKView, drawInRect rect: CGRect) {
        glClearColor(0.65, 0.65, 0.65, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
        
        
        for (ID, droplet) in worldModel.droplets {
            render.RenderDroplet(droplet)
        }
        
        render.RenderSkybox()
        
        for (ID) in Array(worldModel.stains.keys).sorted(>) { // 后添加的在前
            render.RenderStain(worldModel.stains[ID]!)
        }

    }

}
