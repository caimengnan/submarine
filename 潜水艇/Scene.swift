//
//  Scene.swift
//  潜水艇
//
//  Created by targeter on 2020/4/3.
//  Copyright © 2020 targeter. All rights reserved.
//

import SpriteKit
import ARKit
import AVFoundation

let pipeCategory:UInt32 = 1
let imageCategory:UInt32 = 0
let scoreCategory:UInt32 = 2

enum GameStatus {
    case initialize  //初始化
    case running //游戏运行中
    case over //游戏结束
}

class Scene: SKScene,SKPhysicsContactDelegate {
    
    var playerItem: AVPlayerItem?
    var player: AVPlayer?
    
    var positionCallBack:((_ point:CGPoint)->())?
    var score:Int = 0
    
    var image:SKSpriteNode!
    
    //游戏状态的变量
    var gameStatus:GameStatus = .initialize
    //游戏结束标签
    lazy var gameOverLabel:SKLabelNode = {
        let label = SKLabelNode(fontNamed: "AmericanTypewriter")
        label.text = "游戏结束"
        label.fontColor = .red
        return label
    }()
    
    //计分标签
    lazy var scoreLabel:SKLabelNode = {
        let scoreLabel = SKLabelNode(fontNamed: "DBLCDTempBlack")
        scoreLabel.text = "0"
        scoreLabel.fontColor = .yellow
        return scoreLabel
    }()
    
    lazy var scoreNode:SKSpriteNode = {
        let scoreNode = SKSpriteNode(color: .clear, size: CGSize(width: 10, height: 10))
        scoreNode.physicsBody = SKPhysicsBody(rectangleOf: scoreNode.size)
        scoreNode.physicsBody?.affectedByGravity = false
        scoreNode.physicsBody?.categoryBitMask = scoreCategory
        scoreNode.physicsBody?.contactTestBitMask = pipeCategory
        scoreNode.name = "score"
        scoreNode.position = CGPoint.zero
        return scoreNode
    }()
    
    override func didMove(to view: SKView) {
        
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        self.physicsWorld.contactDelegate = self
        
        image = SKSpriteNode(imageNamed: "速抠图")
        image.size = CGSize(width: 60, height: 60)
        image.physicsBody = SKPhysicsBody(rectangleOf:image.size)
        image.physicsBody?.affectedByGravity = false
        
        image.physicsBody?.categoryBitMask = imageCategory
        image.physicsBody?.contactTestBitMask = pipeCategory
        image.position = CGPoint(x: 0, y: 0)

        addChild(image)
        addChild(scoreNode)
        
        scoreLabel.position = CGPoint(x: self.size.width*0.5, y: self.size.height-80)
        scoreLabel.zPosition = 0.9
        addChild(scoreLabel)
        
        //初始化
        initializeGame()
        
        positionCallBack = {
            point in
            if self.gameStatus == .over {
                return
            }
            self.image.position = CGPoint(x: point.x-60, y: point.y)
            self.scoreNode.position = CGPoint(x: self.image.position.x, y: self.size.height-50)
        }
    }
    
    //MARK:游戏初始化
    func initializeGame() {
        //计分重置
        scoreCaculate(num: 0)
        //修改状态
        gameStatus = .initialize
        //移除水管
        removeAllPipes()
        //图片动力学属性消失
        image.physicsBody?.isDynamic = false
    }
    
    //MARK:播放背景音乐
    func playBGM() {
        let path = Bundle.main.path(forResource: "circus.mp3", ofType: nil)
        let sourceUrl = URL(fileURLWithPath: path!)
        playerItem = AVPlayerItem(url: sourceUrl)
        player = AVPlayer(playerItem: playerItem)
        player?.play()
    }
    
    //MARK:关闭背景音乐
    func stopBGM() {
        player?.pause()
    }
    
    //MARK:游戏开始
    func startGame() {
        //游戏开始
        gameStatus = .running
        //水管移动
        moveAction()
        //水管进入
        startCreateRandomPipesAction()
        //图片动力学属性添加
        image.physicsBody?.isDynamic = true
        //开始背景乐
        playBGM()
    }
    
    //MARK:游戏结束
    func gameOver() {
        //关闭背景乐
        stopBGM()
        //修改状态
        self.gameStatus = .over
        //图片动力学属性消失
        image.physicsBody?.isDynamic = false
        //停止添加水管
        stopCreateRandomPipesAcion()
        //添加gameOverLabel标签到场景里
        gameOverLabel.position = CGPoint(x: self.size.width * 0.5, y: self.size.height)
        insertChild(gameOverLabel, at: 0)
        gameOverLabel.zPosition = 0.8
        gameOverLabel.text = "游戏结束\n得分:\(self.score)\n点击重新开始"
        gameOverLabel.numberOfLines = 0
        //让gameoverLabel通过一个动画action移动到屏幕中间
        gameOverLabel.run(SKAction.move(by: CGVector(dx: 0, dy: -self.size.height * 0.5), duration: 0.5)) { [weak self] in
            //动画结束才重新允许用户点击屏幕
            self?.isUserInteractionEnabled = true
        }
    }
    
    //MARK:积分计算
    func scoreCaculate(num:Int) {
        self.score = num
        self.scoreLabel.text = "\(num)"
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
        switch gameStatus {
        case .initialize:      //初始化状态下，点击屏幕开始游戏
            startGame()
        case .running:
            break              //游戏进行中，点击屏幕无响应
        default:
            initializeGame()   //游戏结束状态下，
        }
    }
    
    //MARK:水管移动
    func moveAction() {
        let moveAct = SKAction.wait(forDuration: 0.01)
        let generateAct = SKAction.run {
            self.moveScene()
        }
        run(SKAction.repeatForever(SKAction.sequence([moveAct,generateAct])), withKey: "move")
    }
    
    //MARK:移动和移除
    func moveScene() {
        //make pipe move
        for pipeNode in self.children where pipeNode.name == "pipe" {
            //因为我们要用到水管的size，但是SKNode没有size属性，所以我们要把它转成SKSpriteNode
            if let pipeSprite = pipeNode as? SKSpriteNode {
                //将水管左移2
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
        //创建一个等待的action，等待时间的平均值为秒，变化范围为1秒
        let waitAct = SKAction.wait(forDuration: 1.5)
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
        guard let image = UIImage(named: "topPipe") else { return }
        let topTextture = SKTexture(image: image)
        //利用上水管图片创建一个上水管纹理对象
        let topPipe = SKSpriteNode(texture: topTextture, size: topSize)
        //利用上水管纹理对象和传入的上水管大小参数创建一个上水管对象
        topPipe.name = "pipe" //给这个水管取个名字叫pipe
        topPipe.position = CGPoint(x: self.size.width + topPipe.size.width * 0.5, y: self.size.height - topPipe.size.height * 0.5)
        topPipe.physicsBody = SKPhysicsBody(rectangleOf:topSize)
        topPipe.physicsBody?.isDynamic = false
        topPipe.physicsBody?.affectedByGravity = false
        topPipe.physicsBody?.categoryBitMask = pipeCategory
        topPipe.physicsBody?.contactTestBitMask = imageCategory
        //创建下水管
        let bottomTexture = SKTexture(imageNamed: "bottomPipe")
        let bottomPipe = SKSpriteNode(texture: bottomTexture, size: bottomSize)
        bottomPipe.name = "pipe"
        bottomPipe.position = CGPoint(x: self.size.width + bottomPipe.size.width * 0.5, y: bottomPipe.size.height * 0.5)
        bottomPipe.physicsBody = SKPhysicsBody(rectangleOf:bottomSize)
        bottomPipe.physicsBody?.isDynamic = false
        bottomPipe.physicsBody?.affectedByGravity = false
        bottomPipe.physicsBody?.categoryBitMask = pipeCategory
        bottomPipe.physicsBody?.contactTestBitMask = imageCategory
        
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
        if (contact.bodyA.categoryBitMask == imageCategory && contact.bodyB.categoryBitMask == pipeCategory) {
            //潜水艇碰柱子，游戏结束
            gameOver()
            MusicControl.shared.gameOver()
            
        } else if (contact.bodyA.categoryBitMask == scoreCategory && contact.bodyB.categoryBitMask == pipeCategory) {
            //检测到过柱子，积分+1
            score+=1
            self.scoreCaculate(num: score)
            MusicControl.shared.turnOver()
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
