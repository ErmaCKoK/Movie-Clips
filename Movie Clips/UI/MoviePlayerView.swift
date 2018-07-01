//
//  MoviePlayerView.swift
//  Movie Clips
//
//  Created by Andrii Kurshyn on 01.07.2018.
//  Copyright © 2018 Andrii Kurshyn. All rights reserved.
//

import AVFoundation
import UIKit

class PlayerView: UIView {
    var player: AVPlayer? {
        get { return playerLayer.player }
        set { playerLayer.player = newValue }
    }
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    override class var layerClass : AnyClass {
        return AVPlayerLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commoInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commoInit()
    }
    
    private func commoInit() {
        self.playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.isUserInteractionEnabled = false
    }
    
}

class MoviePlayerView: UIView {

    fileprivate var playerView: PlayerView!
    fileprivate var playImageView: UIImageView!
    fileprivate var playButton: UIButton!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commoInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commoInit()
    }
    
    private func commoInit() {
        
        // setup Player View
        
        self.playerView = PlayerView()
        self.playerView.frame = self.bounds
        self.playerView.backgroundColor = UIColor.clear
        self.playerView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        self.addSubview(playerView)
        
        
        // setup Play Image View
        
        self.playImageView = UIImageView(image: UIImage(named: "play-icon"))
        self.playImageView.frame.size = CGSize(width: 48, height: 48)
        self.playImageView.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        self.playImageView.contentMode = .scaleAspectFit
        self.playImageView.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        self.playImageView.backgroundColor = .clear
        self.playImageView.isHidden = true
        self.addSubview(playImageView)
        
        
        // setup Play Button
        
        self.playButton = UIButton(frame: self.bounds)
        self.playButton.autoresizingMask = [.flexibleHeight,.flexibleWidth]
        self.playButton.addTarget(self, action: #selector(self.handlePlayButton(_:)), for: .touchUpInside)
        self.addSubview(self.playButton)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd), name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    var url: URL? {
        didSet {
            
            guard let url = url else {
                self.playerView.player = nil
                self.playImageView.isHidden = true
                return
            }
            
            self.playerView.player = AVPlayer(url: url)
            self.playImageView.isHidden = false
        }
    }
    
    func play() {
        if  self.playerView.player == nil { return }
        
        self.playImageView.isHidden = true
        self.playerView.player?.play()
    }
    
    func pause() {
        if self.playerView.player == nil { return }
        
        self.playImageView.isHidden = false
        self.playerView.player?.pause()
    }

    @objc private func handlePlayButton(_ sender: UIButton) {
        self.play()
    }
    
    // MARK: Notifications
    
    @objc private func playerItemDidReachEnd(_ notification: Notification) {
        guard (notification.object as? AVPlayerItem) == self.playerView.player?.currentItem else { return }
        
        self.playImageView.isHidden = false
        self.playerView.player?.seek(to: kCMTimeZero)
    }
}
