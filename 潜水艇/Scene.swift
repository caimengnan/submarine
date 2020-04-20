//
//  Scene.swift
//  潜水艇
//
//  Created by targeter on 2020/4/3.
//  Copyright © 2020 targeter. All rights reserved.
//

import SpriteKit
import ARKit

let pipeCategory:UInt32 = 0x1<<1
let birdCategory:UInt32 = 0x1<<0

enum GameStatus {
    case initialize  //初始化
    case running //游戏运行中
    case over //游戏结束
}

class Scene: SKScene,SKPhysicsContactDelegate {
    
    var positionCallBack:((_ point:CGPoint)->())?
    var isGameOver:Bool = false
    var image:SKSpriteNode!
    //游戏状态的变量
    var gameStatus:GameStatus = .initialize
    //游戏结束标签
    lazy var gameOverLabel:SKLabelNode = {
        let label = SKLabelNode(fontNamed: "Chalkduster")
        label.text = "GameOver"
        return label
    }()
    
    override func didMove(to view: SKView) {
        
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        self.physicsWorld.contactDelegate = self
        
        image = SKSpriteNode(imageNamed: "速抠图")
        image.size = CGSize(width: 60, height: 60)
        image.physicsBody = SKPhysicsBody(rectangleOf:image.size)
        image.physicsBody?.affectedByGravity = false
        
        image.physicsBody?.categoryBitMask = birdCategory
        image.physicsBody?.contactTestBitMask = pipeCategory
        image.position = CGPoint(x: 0, y: 0)
        
        addChild(image)
        
        //初始化
        initializeGame()
        
        positionCallBack = {
            point in
            if self.isGameOver == true {
                return
            }
            self.image.position = CGPoint(x: point.x-60, y: point.y)
        }
    }
    
    //MARK:游戏初始化
    func initializeGame() {
        //修改状态
        gameStatus = .initialize
        //移除水管
        removeAllPipes()
        //图片动力学属性消失
        image.physicsBody?.isDynamic = false
    }
    
    //MARK:游戏开始
    func startGame() {
        //游戏开始
        gameStatus = .running
        //水管进入
        startCreateRandomPipesAction()
        //图片动力学属性添加
        image.physicsBody?.isDynamic = true
    }
    
    //MARK:游戏结束
    func gameOver() {
        //图片动力学属性消失
        image.physicsBody?.isDynamic = false
        //停止添加水管
        stopCreateRandomPipesAcion()
        //添加gameOverLabel标签到场景里
        gameOverLabel.position = CGPoint(x: self.size.width * 0.5, y: self.size.height)
        addChild(gameOverLabel)
        insertChild(gameOverLabel, at: 0)
        //让gameoverLabel通过一个动画action移动到屏幕中间
        gameOverLabel.run(SKAction.move(by: CGVector(dx: 0, dy: -self.size.height * 0.5), duration: 0.5)) { [weak self] in
            //动画结束才重新允许用户点击屏幕
            self?.isUserInteractionEnabled = true
        }
    }
    
    //移除场景中的所有水管
    func removeAllPipes() {
        for pipe in self.children where pipe.name == "pipe" {
            pipe.removeFromParent()
        }
        gameOverLabel.removeFromParent()
    }
    
    //MARK:点击开始
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        switch gameStatus {
//        case .initialize:      //初始化状态下，点击屏幕开始游戏
//            startGame()
//        case .running:
//            break              //游戏进行中，点击屏幕无响应
//        default:
//            initializeGame()   //游戏结束状态下，
//        }
        
        startGame()
        
    }
    
    //MARK:floor移动
    func move() {
        let moveAct = SKAction.wait(forDuration: 0.01)
        let generateAct = SKAction.run {
            self.moveScene()
        }
        run(SKAction.repeatForever(SKAction.sequence([moveAct,generateAct])), withKey: "move")
    }
    
    //MARK:水管移动
    func moveScene() {
        //make pipe move
        for pipeNode in self.children where pipeNode.name == "pipe" {
            //因为我们要用到水管的size，但是SKNode没有size属性，所以我们要把它转成SKSpriteNode
            if let pipeSprite = pipeNode as? SKSpriteNode {
                //将水管左移1
                pipeSprite.position = CGPoint(x: pipeSprite.position.x - 2, y: pipeSprite.position.y)
                //检查水管是否完全超出屏幕左侧了，如果是则将它从场景里移除掉
                if pipeSprite.position.x < -pipeSprite.size.width * 0.5 {
                    pipeSprite.removeFromParent()
                }
            }
        }
    }
    
    //MARK:开始重复创建水管
    func startCreateRandomPipesAction() {
        //创建一个等待的action，等待时间的平均值为3.5秒，变化范围为1秒
        let waitAct = SKAction.wait(forDuration: 3.5, withRange: 1.0)
        //创建一个产生随机水管的action，这个action实际上就是我们下面新添加的那个createRandomPipes()方法
        let generatePipeAct = SKAction.run {
            self.createRandomPipes()
        }
        //让场景开始重复循环执行“等待->创建->等待->创建...”
        //并且给这个循环的动作设置一个叫做createPipe的key类标识它
        run(SKAction.repeatForever(SKAction.sequence([waitAct,generatePipeAct])), withKey: "createPipe")
    }
    
    //MARK:具体某一次创建一对水管
    func createRandomPipes() {
        let height = self.size.height
        let pipeGap = CGFloat(arc4random_uniform(60)) + image.size.width*2
        let pipeWidth:CGFloat = 60
        let topHeight = CGFloat(arc4random_uniform(UInt32(height/2))) + height/4
        let bottomPipeHeight = height - pipeGap - topHeight
        addPipes(topSize: CGSize(width: pipeWidth, height: topHeight), bottomSize: CGSize(width: pipeWidth, height: bottomPipeHeight))
    }
    
    //MARK:添加水管到场景里
    func addPipes(topSize:CGSize,bottomSize:CGSize) {
        //创建上水管
        let topTextture = SKTexture(imageNamed: "topPipe")
        //利用上水管图片创建一个上水管纹理对象
        let topPipe = SKSpriteNode(texture: topTextture, size: topSize)
        //利用上水管纹理对象和传入的上水管大小参数创建一个上水管对象
        topPipe.name = "pipe" //给这个水管取个名字叫pipe
        topPipe.position = CGPoint(x: self.size.width + topPipe.size.width * 0.5, y: self.size.height - topPipe.size.height * 0.5)
        topPipe.physicsBody = SKPhysicsBody(rectangleOf:topSize)
        topPipe.physicsBody?.isDynamic = false
        topPipe.physicsBody?.affectedByGravity = false
        topPipe.physicsBody?.categoryBitMask = pipeCategory
        topPipe.physicsBody?.contactTestBitMask = birdCategory
        //创建下水管
        let bottomTexture = SKTexture(imageNamed: "bottomPipe")
        let bottomPipe = SKSpriteNode(texture: bottomTexture, size: bottomSize)
        bottomPipe.name = "pipe"
        bottomPipe.position = CGPoint(x: self.size.width + bottomPipe.size.width * 0.5, y: bottomPipe.size.height * 0.5)
        bottomPipe.physicsBody = SKPhysicsBody(rectangleOf:bottomSize)
        bottomPipe.physicsBody?.isDynamic = false
        bottomPipe.physicsBody?.affectedByGravity = false
        bottomPipe.physicsBody?.categoryBitMask = pipeCategory
        bottomPipe.physicsBody?.contactTestBitMask = birdCategory
        
        //将上下水管天骄到场景中
        addChild(topPipe)
        addChild(bottomPipe)
    }
    
    
    //MARK:碰撞代理事件
    func didBegin(_ contact: SKPhysicsContact) {
        print("发生碰撞")
        if self.gameStatus != .running {
            return
        }
        var bodyA:SKPhysicsBody
        var bodyB:SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            bodyA = contact.bodyA
            bodyB = contact.bodyB
        } else {
            bodyA = contact.bodyB
            bodyB = contact.bodyA
        }
        if (contact.bodyA.categoryBitMask == birdCategory && contact.bodyB.categoryBitMask == pipeCategory) {
            gameOver()
        }
        
    }
    
    
    //MARK:停止创建水管
    func stopCreateRandomPipesAcion() {
        self.removeAction(forKey: "createPipe")
        self.removeAction(forKey: "move")
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        
    }
    
    
}
