//
//  MoviesViewController.swift
//  MovieViewer
//
//  Created by John Nguyen on 9/12/17.
//  Copyright © 2017 John Nguyen. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UISearchBarDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var errorMsgLabel: UILabel!
    @IBOutlet weak var segmentView: UISegmentedControl!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var errorMsgView: UIView!
    @IBOutlet weak var topBarView: UIView!
    
    var endpoint: String = ""
    var movies: [NSDictionary]?
    var moviesFiltered: [NSDictionary]?
    var searchActive: Bool = false
    var showErrorMsg = false
    
    func fetchMovies( _ refreshControl: UIRefreshControl ) {
        
        let url = URL(string:"https://api.themoviedb.org/3/movie/\(endpoint)?api_key=a07e22bc18f5cb106bfe4cc1f83ad8ed")
        var request = URLRequest(url: url!)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        let session = URLSession(
            configuration: URLSessionConfiguration.default,
            delegate:nil,
            delegateQueue:OperationQueue.main
        )
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        let task : URLSessionDataTask = session.dataTask(with: request, completionHandler:
        { (dataOrNil, response, error) in
            MBProgressHUD.hide(for: self.view, animated: true)
            
            if let error = error {
                if( self.showErrorMsg == false ) {
                    self.showErrorMsg = true
                    // Slide down Network error message
                    UIView.animate(withDuration: 0.5, delay: 1.0, options: [.curveEaseOut], animations: {
                        self.topBarView.center.y += self.errorMsgView.frame.size.height
                        self.view.layoutIfNeeded()
                    }, completion: nil)
                    
                }
            }
            else if let data = dataOrNil {
                
                if let dictionary = try! JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                    self.movies = dictionary["results"] as? [NSDictionary]
                    self.tableView.reloadData()
                    self.collectionView.reloadData()
                    
                    if( self.showErrorMsg == true ) {
                        self.showErrorMsg = false
                        // Slide Network error message back up
                        UIView.animate(withDuration: 0.5, delay: 1.0, options: [.curveEaseOut], animations: {
                            self.topBarView.center.y -= self.errorMsgView.frame.size.height
                            self.view.layoutIfNeeded()
                        }, completion: nil)
                    }
                }
                
            }
            // Tell the refreshControl to stop spinning
            refreshControl.endRefreshing()
        });
        task.resume()

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        searchBar.delegate = self
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(fetchMovies(_:)), for: UIControlEvents.valueChanged)

        tableView.insertSubview(refreshControl, at: 0)
        
        collectionView.isHidden = true
        tableView.isHidden = false
        
        // Do any additional setup after loading the view.
        fetchMovies( refreshControl )
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: animated)
        }
        
        searchBar.endEditing(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if( isFiltering() ) {
            return moviesFiltered!.count
        }
        
        if let movies = movies {
            return movies.count
        }

        return 0

    }
    
    func setPosterImage( movie: NSDictionary, imageView: UIImageView )
    {
        let baseURL = "http://image.tmdb.org/t/p/w500"
        if let path = movie["poster_path"] as? String {
            let posterURL = NSURL(string: baseURL + path)!
            let imageRequest = NSURLRequest(url: posterURL as URL)
            imageView.setImageWith(
                imageRequest as URLRequest,
                placeholderImage: nil,
                success: { (imageRequest, imageResponse, image) -> Void in
                    
                    // imageResponse will be nil if the image is cached
                    if imageResponse != nil {
                        //print("Image was NOT cached, fade in image")
                        imageView.alpha = 0.0
                        imageView.image = image
                        UIView.animate(withDuration: 0.3, animations: { () -> Void in
                            imageView.alpha = 1.0
                        })
                    } else {
                        //print("Image was cached so just update the image")
                        imageView.image = image
                    }
                },
                failure: { (imageRequest, imageResponse, error) -> Void in
                    // do something for the failure condition
            })
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell
        var movie: NSDictionary
        
        if ( isFiltering() ) {
            movie = moviesFiltered![indexPath.row]
        } else {
            movie = movies![indexPath.row]
        }
        
        let title = movie["title"] as! String
        let overview = movie["overview"] as! String
        
        cell.titleLabel.text = title
        cell.overviewLabel.text = overview
        
        setPosterImage( movie: movie, imageView: cell.posterView )

        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if( isFiltering() ) {
            return moviesFiltered!.count
        }
        
        if let movies = movies {
            return movies.count
        }

        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MovieCollectionCell", for: indexPath) as! MovieCollectionCell
        
        var movie: NSDictionary
        
        if ( isFiltering() ) {
            movie = moviesFiltered![indexPath.row]
        } else {
            movie = movies![indexPath.row]
        }
        
        setPosterImage( movie: movie, imageView: cell.posterView )
        
        return cell
    }

    @IBAction func viewTypeSelected(_ sender: UISegmentedControl) {

        if( sender.selectedSegmentIndex == 1 ) {
            collectionView.isHidden = false
            tableView.isHidden = true
        }
        else {
            collectionView.isHidden = true
            tableView.isHidden = false
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
    
    func isFiltering() -> Bool {
        return !searchBarIsEmpty()
    }
    
    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchBar.text?.isEmpty ?? true
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        moviesFiltered = []
        
        for index in 0..<movies!.count {
            let movie = movies?[index]
            
            
            let title = movie?["title"]! as! String
            let overview = movie?["overview"]! as! String

            if title.containsIgnoreCase(searchText) || overview.containsIgnoreCase(searchText) {
                moviesFiltered!.append(movie!)
            }
        }

        if(moviesFiltered!.count == 0){
            searchActive = false;
        } else {
            searchActive = true;
        }
        self.tableView.reloadData()
        self.collectionView.reloadData()

    }
 
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        var indexPath: IndexPath?
        
        if let _ = sender as? UITableViewCell {
            let cell = sender as! UITableViewCell
            indexPath = tableView.indexPath(for: cell)
        } else {
            let cell = sender as! UICollectionViewCell
            indexPath = collectionView.indexPath(for: cell)
        }
        
        var movie: NSDictionary
        
        if ( isFiltering() ) {
            movie = moviesFiltered![indexPath!.row]
        } else {
            movie = movies![indexPath!.row]
        }
        
        let detailViewController = segue.destination as! DetailViewController
        detailViewController.movie = movie

        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }


}
