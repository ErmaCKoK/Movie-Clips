//
//  Movie.swift
//  Movies
//
//  Created by Andrii Kurshyn on 30.06.2018.
//  Copyright © 2018 Andrii Kurshyn. All rights reserved.
//

import Foundation

class Movie: Mapped {
    
    private(set) var id: String
    
    var imageUrl: String
    var videoUrl: String
    
    var videoURL: URL { return URL(string: self.videoUrl)! }
    
    required init?(with dict: [String: Any]) {
        guard
            let id = dict["id"] as? Int,
            let imageUrl = dict["imageUrl"] as? String,
            let videoUrl = dict["videoUrl"] as? String
        else {
            return nil
        }
        
        self.id = "\(id)"
        self.imageUrl = imageUrl
        self.videoUrl = videoUrl
    }
}
