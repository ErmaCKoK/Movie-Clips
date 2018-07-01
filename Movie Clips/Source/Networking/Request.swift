//
//  Request.swift
//  Movie Clips
//
//  Created by Andrii Kurshyn on 30.06.2018.
//  Copyright © 2018 Andrii Kurshyn. All rights reserved.
//

import Foundation

private let BaseUrl = "https://private-04a55-videoplayer1.apiary-mock.com"

protocol Request {
    
}

protocol Mapped {
    init?(with dict: [String: Any])
}

extension Request {
    
    func get<T: Mapped>(path: String, object: T.Type,  completion: @escaping ([T], Error?)->()) {
        Networking.get(with: "\(BaseUrl)/\(path)") { (json, error) in
            guard let array = json as? [[String: Any]] else {
                completion([], error)
                return
            }
            
            let objects = array.compactMap({ object.init(with: $0) })
            completion(objects, error)
        }
    }
}
