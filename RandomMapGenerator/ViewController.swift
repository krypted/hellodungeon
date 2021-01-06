//
//  ViewController.swift
//  RandomMapGenerator
//
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var mapView: RandomMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    @IBAction func randomAction(_ sender: Any) {
        while !mapView.generate() {
            
        }
    }
    
    var currentIndex = 0
    var currentImages: [UIImage] = []
    
    
    @objc func showVC() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let destinationController = storyboard.instantiateViewController(identifier: "SomeVC") as! SomeVC
        destinationController.photos = currentImages
        destinationController.index = currentIndex
        navigationController?.pushViewController(destinationController, animated: true)
        
    }
    
    @IBAction func saveAction(_ sender: Any) {
        let image = mapView.asImage()
        ImageSaver().writeToPhotoAlbum(image: image)
    }
    
    class SomeVC: UIViewController {
        var photos: [UIImage] = []
        var index: Int = 0
    }
    
}

