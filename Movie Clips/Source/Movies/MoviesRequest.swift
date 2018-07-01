//
//  MovieRequest.swift
//  Movies
//
//  Created by Andrii Kurshyn on 30.06.2018.
//  Copyright © 2018 Andrii Kurshyn. All rights reserved.
//

import Foundation

class MovieRequest: Request {
    
    func execute(completion: @escaping  ([Movie])->()) {
        self.get(path: "pictures", object: Movie.self) { (clips, error) in
            completion(clips)
        }
    }
}
