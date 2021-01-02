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
//        mapView.generate()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let frame = self.view.frame
        mapView.generate()
    }

}

