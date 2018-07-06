//
//  MovieViewController.swift
//  Movies
//
//  Created by Andrii Kurshyn on 30.06.2018.
//  Copyright © 2018 Andrii Kurshyn. All rights reserved.
//

import UIKit

class MovieViewController: UIViewController, MovieViewDataSource {

    @IBOutlet weak var moviePlayerView: MoviePlayerView!
    
    var movieView: MovieView {
        return self.view as! MovieView
    }
    
    var clips = [Movie]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.movieView.dataSource  = self
        
        MovieRequest().execute { (clips) in
            self.clips = clips
            self.movieView.reload()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - MovieView Data Source

    func numberOfMovies(_ movieView: MovieView) -> Int {
        return self.clips.count
    }
    
    func movieView(_ movieView: MovieView, movieAt index: Int) -> Movie {
        return self.clips[index]
    }
    
}

