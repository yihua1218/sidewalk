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
import GoogleAPIClientForREST
import GoogleSignIn
import Font_Awesome_Swift
import PureLayout

class ViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate, GIDSignInDelegate, GIDSignInUIDelegate {
    private let scopes = [kGTLRAuthScopeDriveReadonly]
    private let service = GTLRDriveService()

    private var renderer: GMUGeometryRenderer!
    private var kmlParser: GMUKMLParser!
    
    // Pathlog
    var pathlog = String()
    
    // Locations
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var lastLocation: CLLocation?
    
    var mapView: GMSMapView!
    var zoomLevel: Float = 21.0
    var path : GMSMutablePath?
    var polyline : GMSPolyline!
    
    // Optins and state
    var state = true
    var start = false
    var login = false
    var follow = false
    var first_location = false
    
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

    var stateButton : UIButton!
    var okImage : UIImage!
    var okImageHighlighted : UIImage!
    var blockImage : UIImage!
    var blockImageHighlighted : UIImage!

    var triangleButton : UIButton!
    var triangleImage : UIImage!
    var triangleImageHighlighted : UIImage!
    
    // Sign-In / Sign-Out
    var signInButton : GIDSignInButton!
    var signInImage : UIImage!
    var signInImageHighlighted : UIImage!
    
    var signOutButton : UIButton!
    var signOutImage : UIImage!
    var signOutImageHighlighted : UIImage!

    // Color
    let green = UIColor.init(red: 15.0/255.0, green: 157.0/255.0, blue: 88.0/255.0, alpha: 1.0)
    let red = UIColor.init(red: 165.0/255.0, green: 39.0/255.0, blue: 20.0/255.0, alpha: 1.0)
    let yellow = UIColor.init(red: 255.0/255.0, green: 214.0/255.0, blue: 0.0/255.0, alpha: 1.0)
    var color = UIColor.init(red: 15.0/255.0, green: 157.0/255.0, blue: 88.0/255.0, alpha: 1.0)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Google Sign In
        GIDSignIn.sharedInstance().clientID = "688342738323-0f3cmkcfv04ilgq885achndjvb83kio3.apps.googleusercontent.com"
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().scopes.append("https://www.googleapis.com/auth/drive")
        GIDSignIn.sharedInstance().signInSilently()

        locationManager.distanceFilter = kCLLocationAccuracyBest;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.delegate = self;
        locationManager.allowsBackgroundLocationUpdates = true
        
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
        
        // Sign-In
        signInImage = UIImage.init(bgIcon: .FACircle, bgTextColor: .black, topIcon: .FASignIn, topTextColor: .white, bgLarge: true)
        signInImageHighlighted = UIImage.init(bgIcon: .FACircle, bgTextColor: .black, topIcon: .FASignIn, topTextColor: .gray, bgLarge: true)
        signOutImage = UIImage.init(bgIcon: .FACircle, bgTextColor: .black, topIcon: .FASignOut, topTextColor: .white, bgLarge: true)
        signOutImageHighlighted = UIImage.init(bgIcon: .FACircle, bgTextColor: .black, topIcon: .FASignOut, topTextColor: .gray, bgLarge: true)
        signInButton = GIDSignInButton()
        // signInButton.setImage(signInImage, for: .normal)
        // signInButton.setImage(signInImageHighlighted, for: .highlighted)
        view.addSubview(signInButton)
        signInButton.autoPinEdge(toSuperviewEdge: ALEdge.top, withInset: 20.0)
        signInButton.autoPinEdge(toSuperviewEdge: ALEdge.left, withInset: 20.0)
        // signInButton.addTarget(self, action: #selector(signInButtonClick), for: .touchDown)
        
        signOutButton = UIButton()
        signOutButton.setImage(signOutImage, for: .normal)
        signOutButton.setImage(signOutImageHighlighted, for: .highlighted)
        view.addSubview(signOutButton)
        signOutButton.isHidden = true
        signOutButton.autoPinEdge(toSuperviewEdge: ALEdge.top, withInset: 20.0)
        signOutButton.autoPinEdge(toSuperviewEdge: ALEdge.left, withInset: 20.0)
        signOutButton.addTarget(self, action: #selector(signOutButtonClick), for: .touchDown)

        // Panel
        recordImage = UIImage.init(bgIcon: .FACircle, bgTextColor: .black, topIcon: .FACircle, topTextColor: .red, bgLarge: true)
        recordImageHighlighted = UIImage.init(bgIcon: .FACircle, bgTextColor: .black, topIcon: .FACircle, topTextColor: .white, bgLarge: true)
        pauseImage = UIImage.init(bgIcon: .FACircle, bgTextColor: .black, topIcon: .FAPause, topTextColor: .white, bgLarge: true)
        pauseImageHighlighted = UIImage.init(bgIcon: .FACircle, bgTextColor: .black, topIcon: .FAPause, topTextColor: .gray, bgLarge: true)
        pauseButton = UIButton()
        pauseButton.setImage(recordImage, for: .normal)
        pauseButton.setImage(recordImageHighlighted, for: .highlighted)
        view.addSubview(pauseButton)
        pauseButton.autoPinEdge(toSuperviewEdge: ALEdge.bottom, withInset: 10.0)
        pauseButton.autoAlignAxis(toSuperviewAxis: ALAxis.vertical)
        pauseButton.addTarget(self, action: #selector(pauseButtonClick), for: .touchDown)
        
        recordButton = UIButton()
        recordButton.setImage(recordImage, for: .normal)
        recordButton.setImage(recordImageHighlighted, for: .highlighted)
        if (false) {
            view.addSubview(recordButton)
            recordButton.autoPinEdge(ALEdge.right, to: ALEdge.left, of: pauseButton, withOffset: -10)
            recordButton.autoAlignAxis(ALAxis.horizontal, toSameAxisOf: pauseButton)
            recordButton.addTarget(self, action: #selector(recordButtonClick), for: .touchDown)
        }

        okImage = UIImage.init(bgIcon: .FACircle, bgTextColor: .black, topIcon: .FACheck, topTextColor: green, bgLarge: true)
        okImageHighlighted = UIImage.init(bgIcon: .FACircle, bgTextColor: .black, topIcon: .FACheck, topTextColor: .white, bgLarge: true)
        blockImage = UIImage.init(bgIcon: .FACircle, bgTextColor: .black, topIcon: .FABan, topTextColor: red, bgLarge: true)
        blockImageHighlighted = UIImage.init(bgIcon: .FACircle, bgTextColor: .black, topIcon: .FABan, topTextColor: .white, bgLarge: true)
        stateButton = UIButton()
        stateButton.setImage(okImage, for: .normal)
        stateButton.setImage(okImageHighlighted, for: .highlighted)
        view.addSubview(stateButton)
        stateButton.autoPinEdge(ALEdge.right, to: ALEdge.left, of: pauseButton, withOffset: -10)
        stateButton.autoAlignAxis(ALAxis.horizontal, toSameAxisOf: pauseButton)
        stateButton.addTarget(self, action: #selector(stateButtonClick), for: .touchDown)

        triangleImage = UIImage.init(bgIcon: .FACircle, bgTextColor: .black, topIcon: .FAExclamationTriangle, topTextColor: yellow, bgLarge: true)
        triangleImageHighlighted = UIImage.init(bgIcon: .FACircle, bgTextColor: .black, topIcon: .FAExclamationTriangle, topTextColor: .white, bgLarge: true)
        triangleButton = UIButton()
        triangleButton.setImage(triangleImage, for: .normal)
        triangleButton.setImage(triangleImageHighlighted, for: .highlighted)
        view.addSubview(triangleButton)
        triangleButton.autoPinEdge(ALEdge.right, to: ALEdge.left, of: stateButton, withOffset: -10)
        triangleButton.autoAlignAxis(ALAxis.horizontal, toSameAxisOf: pauseButton)
        triangleButton.addTarget(self, action: #selector(triangleButtonClick), for: .touchDown)

        stopImage = UIImage.init(bgIcon: .FACircle, bgTextColor: .black, topIcon: .FAStop, topTextColor: .white, bgLarge: true)
        stopImageHighlighted = UIImage.init(bgIcon: .FACircle, bgTextColor: .black, topIcon: .FAStop, topTextColor: .gray, bgLarge: true)
        stopButton = UIButton()
        stopButton.setImage(stopImage, for: .normal)
        stopButton.setImage(stopImageHighlighted, for: .highlighted)
        view.addSubview(stopButton)
        stopButton.autoPinEdge(ALEdge.left, to: ALEdge.right, of: pauseButton, withOffset: 10.0)
        stopButton.autoAlignAxis(ALAxis.horizontal, toSameAxisOf: pauseButton)
        stopButton.addTarget(self, action: #selector(stopButtonClick), for: .touchDown)
        
        // Callback for entring background
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: .UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        var distance = 0.0
        print("Location: \(location)")
        
        if (lastLocation != nil) {
            distance = location.distance(from: lastLocation!)
            print("distance: \(distance)")
        }
        
        lastLocation = location
        
        let dateFormatterPrint = DateFormatter()
        let timeFormatterPrint = DateFormatter()
        // 2017-09-18T21:29:40Z
        dateFormatterPrint.dateFormat = "yyyy-MM-dd"
        timeFormatterPrint.dateFormat = "hh:mm:ss"
        let date = Date()
        let now_date = dateFormatterPrint.string(from: date)
        let now_time = timeFormatterPrint.string(from: date)
        pathlog = pathlog +
            "\(now_date)T\(now_time)Z,\(location.coordinate.latitude),\(location.coordinate.longitude)," +
            "\(location.altitude),\(location.course),\(location.speed)\n"
        
        
        if (path != nil && distance > 1.0) {
            path?.add(CLLocationCoordinate2D(latitude:location.coordinate.latitude, longitude: location.coordinate.longitude))
            polyline.path = path
            polyline.strokeWidth = 10
            polyline.strokeColor = color
            polyline.map = mapView
        }
        
        if follow || first_location == false {
            let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                                  longitude: location.coordinate.longitude,
                                                  zoom: mapView.camera.zoom)
            
            if mapView.isHidden {
                mapView.isHidden = false
                mapView.camera = camera
            } else {
                mapView.animate(to: camera)
            }
            first_location = true
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
    
    @objc func signInButtonClick(sender: UIButton) {
        print("signInButtonClick")
        if (login == false) {
            print("signIn")
            login = true
            // signInButton.setImage(signOutImage, for: .normal)
            // signInButton.setImage(signOutImageHighlighted, for: .highlighted)
        } else {
            print("signOut")
            login = false
            // signInButton.setImage(signInImage, for: .normal)
            // signInButton.setImage(signInImageHighlighted, for: .highlighted)
        }
    }
    
    @objc func signOutButtonClick(sender: UIButton) {
        print("signOutButtonClick")
        GIDSignIn.sharedInstance().signOut()
        
        signInButton.isHidden = false
        signOutButton.isHidden = true
        login = false

        /*
        if (login == false) {
            print("signIn")
            login = true
            // signInButton.setImage(signOutImage, for: .normal)
            // signInButton.setImage(signOutImageHighlighted, for: .highlighted)
        } else {
            print("signOut")
            login = false
            // signInButton.setImage(signInImage, for: .normal)
            // signInButton.setImage(signInImageHighlighted, for: .highlighted)
        } */
    }
    
    @objc func recordButtonClick(sender: UIButton) {
        print("recordButtonClick")
        start = true
    }
    
    @objc func triangleButtonClick(sender: UIButton) {
        print("triangleButtonClick")
        if (lastLocation != nil) {
            let position = CLLocationCoordinate2D(latitude:(lastLocation?.coordinate.latitude)!, longitude: (lastLocation?.coordinate.longitude)!)
            let marker = GMSMarker(position: position)
            marker.icon = UIImage.init(bgIcon: .FACircle, bgTextColor: UIColor(white: 1, alpha: 0.0), topIcon: .FAExclamationTriangle, topTextColor: yellow, bgLarge: true)
            marker.map = mapView
        }
    }

    @objc func stateButtonClick(sender: UIButton) {
        print("stateButtonClick")
        if (state == false) {
            state = true
            color = green
            path = GMSMutablePath()
            path?.add(CLLocationCoordinate2D(latitude:(lastLocation?.coordinate.latitude)!, longitude: (lastLocation?.coordinate.longitude)!))
            polyline = GMSPolyline(path: path)
            stateButton.setImage(okImage, for: .normal)
            stateButton.setImage(okImageHighlighted, for: .highlighted)
        } else {
            state = false
            color = red
            path = GMSMutablePath()
            path?.add(CLLocationCoordinate2D(latitude:(lastLocation?.coordinate.latitude)!, longitude: (lastLocation?.coordinate.longitude)!))
            polyline = GMSPolyline(path: path)
            stateButton.setImage(blockImage, for: .normal)
            stateButton.setImage(blockImageHighlighted, for: .highlighted)
        }
    }

    @objc func pauseButtonClick(sender: UIButton) {
        print("pauseButtonClick")
        
        if (start == false) {
            start = true
            path = GMSMutablePath()
            polyline = GMSPolyline(path: path)
            pauseButton.setImage(pauseImage, for: .normal)
            pauseButton.setImage(pauseImageHighlighted, for: .highlighted)
        } else {
            start = false
            pauseButton.setImage(recordImage, for: .normal)
            pauseButton.setImage(recordImageHighlighted, for: .highlighted)
            path = nil
        }
    }
    
    @objc func stopButtonClick(sender: UIButton) {
        print("stopButtonClick")
        let fileData = pathlog.data(using: .utf8)
        let folderId = "0B8fZpGSJ3Od8cUV3Vy1xNTRCcms"
        let metadata = GTLRDrive_File.init()
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "yyyyMMddhhmmss"
        let date = Date()
        metadata.name = dateFormatterPrint.string(from: date)
        metadata.mimeType = "application/vnd.google-apps.spreadsheet"
        metadata.parents = [folderId]
        
        let uploadParameters = GTLRUploadParameters(data: fileData! , mimeType: "text/csv")
        uploadParameters.shouldUploadWithSingleRequest = true
        let query = GTLRDriveQuery_FilesCreate.query(withObject: metadata, uploadParameters: uploadParameters)
        query.fields = "id"
        self.service.executeQuery(query, completionHandler: {(ticket:GTLRServiceTicket, object:Any?, error:Error?) in
            if error == nil {
                //  print("File ID \(files.identifier)")
            }
            else {
                print("An error occurred: \(String(describing: error))")
            }
        })
    }
    
    @objc func willResignActive(sender: UIButton) {
        print("willResignActive")
        if (start == true) {
            print("background location update")
        } else {
            print("stop location update")
            locationManager.stopUpdatingLocation()
        }
    }
    
    @objc func willEnterForeground(sender: UIButton) {
        print("willEnterForeground")
        print("startUpdatingLocation")
        locationManager.startUpdatingLocation()
    }
    
    // Google Sign In
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if (error == nil) {
            signInButton.isHidden = true
            signOutButton.isHidden = false
            login = true
            // Perform any operations on signed in user here.
            let userId = user.userID                  // For client-side use only!
            let idToken = user.authentication.idToken // Safe to send to the server
            let fullName = user.profile.name
            let givenName = user.profile.givenName
            let familyName = user.profile.familyName
            let email = user.profile.email
            // ...
            print(userId ?? "no userId")
            print(idToken ?? "no idToken")
            print(fullName ?? "no fullName")
            print(givenName ?? "no givenName")
            print(familyName ?? "no familyName")
            print(email ?? "no email")
            print(user.authentication.accessToken ?? "no access token")
            print(user.accessibleScopes ?? "no scopes")
            
            service.authorizer = user.authentication.fetcherAuthorizer()
        } else {
            print("didSignInFor")
            print("\(error.localizedDescription)")
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        if (error == nil) {
            signInButton.isHidden = false
            signOutButton.isHidden = true
            login = false
        } else {
            print("didDisconnectWith")
            print("\(error.localizedDescription)")
        }
    }
}

