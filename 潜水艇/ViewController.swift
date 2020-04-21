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
import GameplayKit

class ViewController: UIViewController, ARSKViewDelegate,ARSessionDelegate,SKPhysicsContactDelegate {
    
    @IBOutlet var sceneView: ARSKView!
    //添加两个地面变量
    var floor1:SKSpriteNode!
    var floor2:SKSpriteNode!
    
    var scene = Scene.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.showsPhysics = true
        sceneView.scene?.physicsWorld.contactDelegate = self
        // Show statistics such as fps and node count
        sceneView.showsFPS = true
        sceneView.showsNodeCount = true
        
        guard ARFaceTrackingConfiguration.isSupported else {
            fatalError("Face tracking is not supported on this device")
        }
        
        // Load the SKScene from 'Scene.sks'
//        if let scene = SKScene(fileNamed: "Scene.sks") {
//            sceneView.presentScene(scene)
//        }
        
        if let view = self.view as! SKView? {
            //通过代码创建一个GameScene类的实例对象
            scene.size = view.bounds.size
            sceneView.presentScene(scene)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARFaceTrackingConfiguration()
        //configuration.planeDetection = .horizontal
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
        image.physicsBody?.isDynamic = false
        image.physicsBody?.categoryBitMask = 3
        image.physicsBody?.contactTestBitMask = 2
        image.position = CGPoint(x: -60, y: 0)
        //node.addChild(image)
    }
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        print("产生碰撞")
    }
    
    
    func view(_ view: ARSKView, willUpdate node: SKNode, for anchor: ARAnchor) {
        //print(node.position)
        
    }
    
    func view(_ view: ARSKView, didUpdate node: SKNode, for anchor: ARAnchor) {
        //print(node.position)
        //node.position = CGPoint(x: node.position.x, y: node.position.y*1.5)
        scene.positionCallBack?(node.position)
    }
    
   
}
