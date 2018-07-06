//
//  UIImageView+Download.swift
//  Movie Clips
//
//  Created by Andrii Kurshyn on 04.07.2018.
//  Copyright © 2018 Andrii Kurshyn. All rights reserved.
//

import UIKit

private struct ImageViewAssociatedKeys {
    static var url = "UIImageView+Download.url"
    static var dataTask = "UIImageView+Download.dataTask"
}

extension UIImageView {
    
    private var dataTask: URLSessionDataTask? {
        get { return objc_getAssociatedObject(self, &ImageViewAssociatedKeys.dataTask) as? URLSessionDataTask }
        set { objc_setAssociatedObject(self, &ImageViewAssociatedKeys.dataTask, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    private var url: String? {
        get { return objc_getAssociatedObject(self, &ImageViewAssociatedKeys.url) as? String }
        set { objc_setAssociatedObject(self, &ImageViewAssociatedKeys.url, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    func setImage(with url: String?, completion: ((_ image: UIImage?, _ view: UIImageView) -> ())? = nil) {
        
        self.dataTask?.cancel()
        self.url = url
        self.image = nil
        
        guard let url = url else {
            completion?(nil, self)
            return
        }
        
        self.dataTask = Networking.downloadImage(at: url) { [weak self] (image) in
            guard let strongSelf = self else { return }
            if url != strongSelf.url || strongSelf.url == nil {
                return
            }
            
            strongSelf.image = image
            completion?(image, strongSelf)
        }
        
    }
    
}

