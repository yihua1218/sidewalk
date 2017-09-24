//
//  ViewController.swift
//  sidewalk
//
//  Created by 梁益華 on 2017/9/23.
//  Copyright © 2017年 Yi-Hua Liang. All rights reserved.
//

import UIKit
import CoreLocation
import GoogleMaps
import GoogleToolboxForMac
import Font_Awesome_Swift
import PureLayout

class ViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {
    private var renderer: GMUGeometryRenderer!
    private var kmlParser: GMUKMLParser!
    
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var mapView: GMSMapView!
    var zoomLevel: Float = 21.0
    let path = GMSMutablePath()
    var polyline : GMSPolyline!
    var start = false
    
    // Panel
    var recordButton : UIButton!
    var recordImage : UIImage!
    var recordImageHighlighted : UIImage!
    var pauseButton : UIButton!
    var pauseImage : UIImage!
    var pauseImageHighlighted : UIImage!
    var stopButton : UIButton!
    var stopImage : UIImage!
    var stopImageHighlighted : UIImage!
    
    // Color
    let green = UIColor.init(red: 15.0/255.0, green: 157.0/255.0, blue: 88.0/255.0, alpha: 1.0)
    let red = UIColor.init(red: 165.0/255.0, green: 39.0/255.0, blue: 20.0/255.0, alpha: 1.0)
    var color = UIColor.init(red: 15.0/255.0, green: 157.0/255.0, blue: 88.0/255.0, alpha: 1.0)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        locationManager.distanceFilter = kCLLocationAccuracyBest;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.delegate = self;
        
        let camera = GMSCameraPosition.camera(withLatitude: 25.0491699, longitude: 121.509634, zoom: zoomLevel)
        mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        mapView.settings.compassButton = true

        // The myLocation attribute of the mapView may be null
        if let mylocation = mapView.myLocation {
            print("User's location: \(mylocation)")
        } else {
            print("User's location is unknown")
        }
        
        polyline = GMSPolyline(path: path)
        polyline.map = mapView
        view = mapView
        
        // https://drive.google.com/uc?authuser=0&id=0B8fZpGSJ3Od8Vzd2T25pVkYzdGc&export=download
        let kml_path = Bundle.main.path(forResource: "doc", ofType: "kml")
        let url = URL(fileURLWithPath: kml_path!)
        kmlParser = GMUKMLParser(url: url)
        kmlParser.parse()
        
        renderer = GMUGeometryRenderer(map: mapView,
                                       geometries: kmlParser.placemarks,
                                       styles: kmlParser.styles)
        
        renderer.render()
        
        // Panel
        pauseImage = UIImage.init(bgIcon: .FACircle, bgTextColor: .black, topIcon: .FAPause, topTextColor: .white, bgLarge: true)
        pauseImageHighlighted = UIImage.init(bgIcon: .FACircle, bgTextColor: .black, topIcon: .FAPause, topTextColor: .gray, bgLarge: true)
        pauseButton = UIButton()
        pauseButton.setImage(pauseImage, for: .normal)
        pauseButton.setImage(pauseImageHighlighted, for: .highlighted)
        view.addSubview(pauseButton)
        pauseButton.autoPinEdge(toSuperviewEdge: ALEdge.bottom, withInset: 10.0)
        pauseButton.autoAlignAxis(toSuperviewAxis: ALAxis.vertical)
        
        recordImage = UIImage.init(bgIcon: .FACircle, bgTextColor: .black, topIcon: .FACircle, topTextColor: .red, bgLarge: true)
        recordImageHighlighted = UIImage.init(bgIcon: .FACircle, bgTextColor: .black, topIcon: .FACircle, topTextColor: .white, bgLarge: true)
        recordButton = UIButton()
        recordButton.setImage(recordImage, for: .normal)
        recordButton.setImage(recordImageHighlighted, for: .highlighted)
        view.addSubview(recordButton)
        recordButton.autoPinEdge(ALEdge.right, to: ALEdge.left, of: pauseButton, withOffset: -10)
        recordButton.autoAlignAxis(ALAxis.horizontal, toSameAxisOf: pauseButton)
        recordButton.addTarget(self, action: #selector(recordButtonClick), for: .touchDown)
        
        stopImage = UIImage.init(bgIcon: .FACircle, bgTextColor: .black, topIcon: .FAStop, topTextColor: .white, bgLarge: true)
        stopImageHighlighted = UIImage.init(bgIcon: .FACircle, bgTextColor: .black, topIcon: .FAStop, topTextColor: .gray, bgLarge: true)
        stopButton = UIButton()
        stopButton.setImage(stopImage, for: .normal)
        stopButton.setImage(stopImageHighlighted, for: .highlighted)
        view.addSubview(stopButton)
        stopButton.autoPinEdge(ALEdge.left, to: ALEdge.right, of: pauseButton, withOffset: 10.0)
        stopButton.autoAlignAxis(ALAxis.horizontal, toSameAxisOf: pauseButton)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        print("Location: \(location)")
        
        if (start) {
            path.add(CLLocationCoordinate2D(latitude:location.coordinate.latitude, longitude: location.coordinate.longitude))
            polyline = GMSPolyline(path: path)
            polyline.strokeWidth = 10
            polyline.strokeColor = green
            polyline.map = mapView
        }
        
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                              longitude: location.coordinate.longitude,
                                              zoom: mapView.camera.zoom)
        
        if mapView.isHidden {
            mapView.isHidden = false
            mapView.camera = camera
        } else {
            mapView.animate(to: camera)
        }
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
            // Display the map using the default location.
            mapView.isHidden = false
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK.")
        }
    }
    
    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: \(error)")
    }
    
    @objc func recordButtonClick(sender: UIButton) {
        print("recordButtonClick")
        start = true
    }
}

