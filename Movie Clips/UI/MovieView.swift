//
//  MovieView.swift
//  Movie Clips
//
//  Created by Andrii Kurshyn on 04.07.2018.
//  Copyright © 2018 Andrii Kurshyn. All rights reserved.
//

import UIKit

private extension UIPanGestureRecognizer {
    
    enum Direction {
        case up
        case down
        case left
        case right
        
        var isVertical: Bool {
            return self == .up || self == .down
        }
        
        var isHorizontal: Bool {
            return self == .left || self == .right
        }
    }
    
    func direction(in view: UIView) -> Direction {
        let velocity = self.velocity(in: view)
        if abs(velocity.x) > abs(velocity.y) {
            return velocity.x < 0 ? .right : .left
        }
        return velocity.y < 0 ? .up : .down
    }
}

private class MovieImageView: UIImageView {

    var minScale: CGFloat = 0.65

    override var frame: CGRect {
        didSet {
            self.setScale()
        }
    }
    
    override var center: CGPoint {
        didSet {
            self.setScale()
        }
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.setScale()
    }

    private func setScale() {
        guard let superview = self.superview else {
            self.transform = .identity
            return
        }

        let midX = min(max(0, self.frame.midX), superview.bounds.width)
        let centerImage = superview.bounds.midX
        var scalePercent = abs(midX/centerImage)

        if midX > centerImage {
            scalePercent = 2 - scalePercent
        }

        let scale = self.minScale + ((1-self.minScale) * scalePercent)
        self.transform = CGAffineTransform(scaleX: scale, y: scale)
    }
}

private struct ThreeViews<T: UIView>: Sequence {
    var previous = T()
    var current = T()
    var next = T()
    
    var views: [T] { return [previous,current,next] }
    
    func makeIterator() -> IndexingIterator<[T]> {
        return  self.views.makeIterator()
    }
    
    @discardableResult
    mutating func reoder(to next: Bool, view: T? = nil) -> T {
        var returnView: T
        if next {
            returnView = self.previous
            
            self.previous = self.current
            
            self.current = self.next
            
            self.next = view ?? returnView
        } else {
            returnView = self.next
            self.next = self.current
            
            self.current = self.previous
            
            self.previous = view ?? returnView
        }
        
        return returnView
    }
}

protocol MovieViewDataSource: class {
    func numberOfMovies(_ movieView: MovieView) -> Int
    func movieView(_ movieView: MovieView, movieAt index: Int) -> Movie
}

class MovieView: UIView, UIGestureRecognizerDelegate {

    weak var dataSource: MovieViewDataSource?
    
    private var playerViews = ThreeViews<MoviePlayerView>()
    private var imageViews = ThreeViews<MovieImageView>()
    
    private var offsreenImageView = MovieImageView()
    private var offsreenIndex: Int?
    
    private var panGesture: UIPanGestureRecognizer!
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    private func commonInit() {
        self.setupGesture()
        self.setupPlayerView()
        self.setupImageViews()
    }
    
    // MARK: - Setup subviews
    
    private func setupGesture() {
        self.panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.hendlePanGesture))
        self.panGesture.minimumNumberOfTouches = 1
        self.panGesture.maximumNumberOfTouches = 1
        self.panGesture.delegate = self
        self.addGestureRecognizer(self.panGesture)
    }
    
    private func setupPlayerView() {
        let frame = CGRect(x: 0, y: 172, width: self.bounds.width, height: 196)
        self.playerViews.forEach({ $0.frame = frame })
        
        self.addSubview(self.playerViews.previous)
        self.addSubview(self.playerViews.current)
        self.addSubview(self.playerViews.next)
    }
    
    private let imageSize = CGSize(width: 113, height: 150)
    private func setupImageViews() {
        let frame = CGRect(x: 0, y: self.bounds.height - imageSize.height - 34, width: imageSize.width, height: imageSize.height)
        
        self.imageViews.forEach({ $0.frame = frame })
        
        self.imageViews.previous.contentMode = .scaleAspectFill
        self.addSubview(self.imageViews.previous)
        
        self.imageViews.current.contentMode = .scaleAspectFill
        self.addSubview(self.imageViews.current)
        
        self.imageViews.next.contentMode = .scaleAspectFill
        self.addSubview(self.imageViews.next)
        
        self.offsreenImageView.frame = frame
        self.offsreenImageView.contentMode = .scaleAspectFill
        self.addSubview(offsreenImageView)
    }
    
    override var frame: CGRect {
        didSet {
            self.didSetFrame()
        }
    }
    
    private func didSetFrame() {
        
        var playerFrame = self.playerViews.current.frame
        playerFrame.origin.y = 172
        playerFrame.size.width = self.bounds.width
        self.playerViews.forEach({ $0.frame = playerFrame })
        
        var imageFrame = CGRect.zero
        imageFrame.size = self.imageSize
        imageFrame.origin.y = self.bounds.height - imageFrame.height - 34
        self.imageViews.forEach({ view in
            view.transform = .identity
            view.frame = imageFrame
        })
        
        self.offsreenImageView.transform = .identity
        self.offsreenImageView.frame = imageFrame
        
        self.layoutViews()
    }
    
    private func layoutViews() {
        
        let currentFrame = self.playerViews.current.frame
        
        // set postion for video player
        self.playerViews.previous.frame.origin.x = currentFrame.minX - self.playerViews.previous.frame.width
        self.playerViews.next.frame.origin.x = currentFrame.minX + currentFrame.width

        // set postion for image views
        let progress = currentFrame.minX / self.bounds.width
        self.imageViews.current.center.x = self.bounds.midX + (self.bounds.midX * progress)
        
        self.imageViews.next.center.x = self.imageViews.current.center.x + self.bounds.midX
        self.imageViews.previous.center.x = self.imageViews.current.center.x - self.bounds.midX

        // set postion for additional image view
        let offscreenPosition = currentFrame.minX < 0 ? 1 : -1
        if offsreenIndex != self.currentIndex + offscreenPosition {
            offsreenIndex = self.currentIndex + offscreenPosition
            
            let offMovie = self.movie(at: offsreenIndex! + offscreenPosition)
            self.offsreenImageView.setImage(with: offMovie?.imageUrl)
        }
        
        
        self.offsreenImageView.isHidden = currentFrame.minX == 0
        self.offsreenImageView.center.x = self.imageViews.current.center.x + (self.bounds.width * CGFloat(offscreenPosition))
    }
    
    // MARK: Public methods
    
    private var numberOfMovies = 0
    private(set) var currentIndex = 0
    
    func reload() {
        self.numberOfMovies = self.dataSource?.numberOfMovies(self) ?? 0
        self.currentIndex = 0
        
        self.setMovies()
    }
    
    func setCurrentIndex(_ index: Int, animated: Bool) {
        var index = index
        
        let goToNext = self.currentIndex < index
        var isUpdatedIndex = self.currentIndex != index
        
        if index >= self.numberOfMovies || index < 0 {
            if self.numberOfMovies == 0 {
                return
            }
            
            index = self.currentIndex
            isUpdatedIndex = false
        }
        
        if animated == false {
            self.currentIndex = index
            
            self.setMovies()
            self.layoutViews()
            return
        }
        
        
        UIView.animate(withDuration: 0.3, animations: {
            
            if isUpdatedIndex == false {
                self.playerViews.current.frame.origin.x = 0
            } else {
                self.playerViews.current.frame.origin.x = self.bounds.width * (goToNext ? -1 : 1)
            }
            
            self.layoutViews()
            
        }) { (flag) in
            self.currentIndex = index
            
            if isUpdatedIndex == false {
                return
            }
            
            self.playerViews.reoder(to: goToNext)
            
            self.offsreenImageView = self.imageViews.reoder(to: goToNext, view: self.offsreenImageView)
            
            if goToNext {
                self.setNextMovie()
            } else {
                self.setPreviousMovie()
            }
            
            self.layoutViews()
        }
    }
    
    private func movie(at index: Int) -> Movie? {
        if index >= self.numberOfMovies || index < 0 || self.numberOfMovies == 0 {
            return nil
        }
        return self.dataSource?.movieView(self, movieAt: index)
    }
    
    private func setMovies() {
        let movie = self.movie(at: self.currentIndex)
        self.playerViews.current.url = movie?.videoURL
        self.imageViews.current.setImage(with: movie?.imageUrl)
        
        self.setPreviousMovie()
        
        self.setNextMovie()
    }
    
    private func setPreviousMovie() {
        let previousMovie = self.movie(at: self.currentIndex - 1)
        self.playerViews.previous.url = previousMovie?.videoURL
        self.imageViews.previous.setImage(with: previousMovie?.imageUrl)
    }
    
    private func setNextMovie() {
        let nextMovie = self.movie(at: self.currentIndex + 1)
        self.playerViews.next.url = nextMovie?.videoURL
        self.imageViews.next.setImage(with: nextMovie?.imageUrl)
    }
    
    
    fileprivate var panDirection: UIPanGestureRecognizer.Direction?
    
    // MARK: - UIGestureRecognizer Delegate
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if self.panGesture != gestureRecognizer { return true }
        
        let direction = self.panGesture.direction(in: self)

        return direction.isHorizontal
    }
    
    // MARK: PanGestureRecognizer Selector
    
    @objc private func hendlePanGesture(_ gesture: UIPanGestureRecognizer) {
        
        if gesture.state == .began {
            self.panDirection = self.panGesture.direction(in: self)
            return
        }
        
        let velocity = gesture.velocity(in: self)
        let direction = self.panGesture.direction(in: self)
        
        
        
        if gesture.state == .ended || gesture.state == .cancelled || gesture.state == .failed {
            
            let velocitySingle = self.panDirection?.isHorizontal == true ? velocity.x : velocity.y
            let isSwipe = abs(velocitySingle) >= 1000
            
            let successPan = abs(self.playerViews.current.frame.midX - self.bounds.midX) > self.bounds.midX * 0.6
            
            if (isSwipe && self.panDirection == direction) || successPan {
                let index = self.panDirection == .left ? -1 : 1
                self.setCurrentIndex(self.currentIndex + index, animated: true)
            } else {
                self.setCurrentIndex(self.currentIndex, animated: true)
            }
            
            self.panDirection = nil
            return
        }
        
        let x = gesture.translation(in: self).x
        
        self.playerViews.current.frame.origin.x += x
        self.layoutViews()
        
        gesture.setTranslation(.zero, in: self)
    }
    
}
