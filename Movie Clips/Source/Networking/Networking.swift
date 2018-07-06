//
//  Networking.swift
//  Movies
//
//  Created by Andrii Kurshyn on 30.06.2018.
//  Copyright © 2018 Andrii Kurshyn. All rights reserved.
//

import UIKit

private extension UIApplication {
    
    static var activityCount: Int = 0
    
    func toggleNetworkActivityIndicator(isVisible: Bool) {
        
        UIApplication.activityCount = isVisible ? UIApplication.activityCount+1 : UIApplication.activityCount-1
        DispatchQueue.main.async {
            self.isNetworkActivityIndicatorVisible = UIApplication.activityCount > 0
        }
        
        if UIApplication.activityCount < 0 {
            UIApplication.activityCount = 0
        }
    }
}

class Networking: NSObject {
    
    
    /// Get the shared instance of Networking.
    static let shared = Networking()
    
    private var session = URLSession.shared
    private var oneRequestAtATimeQueue = [String: URLSessionDataTask]()
    
    private(set) lazy var imageSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.urlCache = .shared
        return URLSession(configuration: configuration)
    }()
    
    /// For performing an async connection to URLRequest on a background worker thread.
    /// The completion block will be executed on URLSession copletion thread.
    ///
    /// - parameter request:    The request URLRequest
    /// - parameter limitTag:   Used to make sure that only one request will be running at a time.
    /// - parameter completion: Returns the response and/or error.
    @discardableResult
    func connect(to request: URLRequest, limitTag: String?, completion: @escaping ((Data?, Error?) -> Void) ) -> URLSessionDataTask{
        UIApplication.shared.toggleNetworkActivityIndicator(isVisible: true)
        
        let dataTask = self.session.dataTask(with: request, completionHandler: { (responseData, response, error) -> Void in
            UIApplication.shared.toggleNetworkActivityIndicator(isVisible: false)
            
            if (error as NSError?)?.code == NSURLErrorCancelled {
                return
            }
            
            if let limitTag = limitTag {
                self.oneRequestAtATimeQueue[limitTag] = nil
            }
            
            completion(responseData, error)
        })
        
        if let limitTag = limitTag {
            if let oldTag = self.oneRequestAtATimeQueue[limitTag] {
                oldTag.cancel()
            }
            self.oneRequestAtATimeQueue[limitTag] = dataTask
        }
        
        dataTask.resume()
        return dataTask
    }
}

// MARK: - Helper

extension Networking {
    
    /// Quick get json data
    ///
    /// - Parameters:
    ///   - url: where get json
    ///   - completion: Returns the json object and/or error.
    static func get(with url: String, completion: @escaping ((Any?, Error?) -> Void)) {
        Networking.shared.connect(to: URLRequest(url: URL(string: url)!), limitTag: url) { (data, error) in
            
            var result: Any?
            var error = error
            
            if let data = data {
                
                do {
                    result = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                } catch let parsingError as NSError {
                    if error == nil {
                        error = parsingError
                    }
                }
            }
            
            DispatchQueue.main.async {
                completion(result, error)
            }
            
        }
    }
    
    @discardableResult
    static func downloadImage(at url: String, completion: @escaping (_ image: UIImage?) -> Void) -> URLSessionDataTask? {
        
        guard let url = URL(string: url) else {
            completion(nil)
            return nil
        }
        
        let request = NSMutableURLRequest(url: url, cachePolicy: Networking.shared.imageSession.configuration.requestCachePolicy, timeoutInterval: 15)
        request.addValue("image/*", forHTTPHeaderField: "Accept")
        
        let task = Networking.shared.imageSession.dataTask(with: url, completionHandler: { (data, responce, error) in
            
            var image: UIImage? = nil
            if let data = data {
                image = UIImage(data: data)
            }
            
            DispatchQueue.main.async {
                completion(image)
            }
        })
        
        task.resume()
        return task
    }
    
}

