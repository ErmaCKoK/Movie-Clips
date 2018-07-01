//
//  ViewController.swift
//  Movies
//
//  Created by Andrii Kurshyn on 30.06.2018.
//  Copyright © 2018 Andrii Kurshyn. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var moviePlayerView: MoviePlayerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MovieRequest().execute { (clips) in
            self.moviePlayerView.url =  clips.first?.videoURL
            self.moviePlayerView.play()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

