//
//  ViewController.swift
//  潜水艇
//
//  Created by targeter on 2020/4/3.
//  Copyright © 2020 targeter. All rights reserved.
//

import UIKit
import SpriteKit
import ARKit

class ViewController: UIViewController, ARSKViewDelegate,ARSessionDelegate,SKPhysicsContactDelegate {
    
    @IBOutlet var sceneView: ARSKView!
    //添加两个地面变量
    var floor1:SKSpriteNode!
    var floor2:SKSpriteNode!
    
    var scene = Scene.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.showsPhysics = true
        sceneView.scene?.physicsWorld.contactDelegate = self
        
        sceneView.showsFPS = true
        sceneView.showsNodeCount = true
        
        //检测手机能不能用人脸追踪功能
        guard ARFaceTrackingConfiguration.isSupported else {
            fatalError("Face tracking is not supported on this device")
        }
        
        if let view = self.view as! SKView? {
            //通过代码创建一个GameScene类的实例对象
            scene.size = view.bounds.size
            sceneView.presentScene(scene)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARFaceTrackingConfiguration()
        sceneView.session.delegate = self
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    // MARK: - ARSKViewDelegate
    func view(_ view: ARSKView, didAdd node: SKNode, for anchor: ARAnchor) {
        let image = SKSpriteNode(imageNamed: "速抠图")
        image.size = CGSize(width: 20, height: 20)
        image.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: "速抠图"), size: CGSize(width: 20, height: 20))
        image.position = CGPoint(x: -60, y: 0)
        //node.addChild(image)
    }
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        print("产生碰撞")
    }
    
    func view(_ view: ARSKView, didUpdate node: SKNode, for anchor: ARAnchor) {
        scene.positionCallBack?(node.position)
    }
    
   
}
