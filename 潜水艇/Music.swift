//
//  Music.swift
//  潜水艇
//
//  Created by targeter on 2020/4/20.
//  Copyright © 2020 targeter. All rights reserved.
//

import Foundation
import AVFoundation

enum MusicType: String {
    case turn_over = "turnover.mp3"
    case bgm = "circus.mp3"
    case gameover = "gameover.mp3"
}

class MusicControl {
    static let shared = MusicControl()
    var playerItem: AVPlayerItem?
    var player: AVPlayer?
    var musicType:MusicType? {
        didSet {
            playMusic(music: (musicType?.rawValue)!)
        }
    }
    
    //翻过障碍
    func turnOver() {
        musicType = .turn_over
    }
    
    //游戏结束
    func gameOver() {
        musicType = .gameover
    }
    
    //背景音乐
    func backgroundMusic() {
        musicType = .bgm
    }
    
    
    
    //播放音效
    fileprivate func playMusic(music:String) {
        let path = Bundle.main.path(forResource: music, ofType: nil)
        let sourceUrl = URL(fileURLWithPath: path!)
        playerItem = AVPlayerItem(url: sourceUrl)
        player = AVPlayer(playerItem: playerItem)
        player?.play()
    }
    
}
