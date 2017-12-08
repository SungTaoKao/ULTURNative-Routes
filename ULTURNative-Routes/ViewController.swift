//
//  ViewController.swift
//  ULTURNative-Routes
//
//  Created by Etome on 2017-09-29.
//  Copyright © 2017 Etome. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Mapbox
import MapboxDirections
import MapboxGeocoder


class ViewController: UIViewController, CLLocationManagerDelegate, MGLMapViewDelegate
{
    
    let directions = Directions.shared
    let geocoder = Geocoder.shared
    var locationManager = CLLocationManager()

    var mapView: MGLMapView!
    var destinationGlobal: CLLocationCoordinate2D!
    var startRoute: Bool = false
    var searchFlag: Bool = false
    var leftTurningPoints = [CLLocationCoordinate2D]()

    
    @IBOutlet weak var speedButton: UIButton!
    @IBOutlet weak var mapviewlayer: UIView!
    
    @IBAction func searchAlert(_ sender: Any) {
        if(!startRoute){
            searchingAlert()
        }else{
            stopAlert()
        }
    }
    @IBAction func clickSpeed(_ sender: Any) {
        zoomIntopoint(mapView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialMap()
    }
    //continue update current location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        print("Current Speed:\(locationManager.location!.speed)")
        let speed = locationManager.location!.speed
        let result = speed * 15/8
        if(result < 0){
            let showing:String = String(0)
            speedButton.setTitle("\(showing) km/h", for: .normal)
            
        }else{
            let showing:String = String(format:"%.1f", result)
            speedButton.setTitle("\(showing) km/h", for: .normal)
        }
        //when you start to go the camera will start trace loation
        //after that please set to false

        if (startRoute){
            zoomIntopoint(mapView)
        }
    }
    //authorized for using location
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                    // do stuff
                }
            }
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
//maker functions
extension ViewController{
    // Use the default marker. See also: our view annotation or custom marker examples.
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        return nil
    }
    
    // Allow callout view to appear when an annotation is tapped.
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    
    // Zoom to the annotation when it is selected
    func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation) {
        if(searchFlag){
            afterSearching()
        }
        let camera = MGLMapCamera(lookingAtCenter: annotation.coordinate, fromDistance: 1000, pitch: 0, heading: 0)
        mapView.setCamera(camera, animated: true)
    }
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        locationManager.requestAlwaysAuthorization()
    }
    //this one called when user click the speed button on the screen
    func zoomIntopoint(_ mapView: MGLMapView){
        let camera = MGLMapCamera(lookingAtCenter: locationManager.location!.coordinate, fromDistance: 1000, pitch: 0, heading: 0)
        mapView.setCamera(camera, animated: true)
    }
    
    //this one called when the searching finished
    func zoomIntoResult(_ mapView: MGLMapView, _ location:GeocodedPlacemark){
        let camera = MGLMapCamera(lookingAtCenter: location.location.coordinate, fromDistance: 1000, pitch: 0, heading: 0)
        mapView.setCamera(camera, animated: true)
        let point = MGLPointAnnotation()
        
        point.coordinate = location.location.coordinate
        point.title = location.name
        point.subtitle = location.qualifiedName
        
        self.mapView.addAnnotation(point)
    }
    func initialMap(){
        mapView = MGLMapView(frame: view.bounds, styleURL: MGLStyle.darkStyleURL())
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        //mapView.setCenter(CLLocationCoordinate2D, animated: <#T##Bool#>)
        mapviewlayer.addSubview(mapView)
        mapviewlayer.addSubview(speedButton)
        // Set the map view's delegate
        mapView.delegate = self
        // Allow the map view to display the user's location
        mapView.showsUserLocation = true
        
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }
}
//searching function
extension ViewController{
    func searchingAndConvert(_ searchDestination: String){
        let opt = ForwardGeocodeOptions(query: searchDestination)
        // To refine the search, you can set various properties on the options object.
        opt.allowedISOCountryCodes = ["CA"]
        opt.allowedScopes = [.address,.postalCode, .pointOfInterest]
        
        _ = geocoder.geocode(opt) { (placemarks, attribution, error) in
            guard let placemark = placemarks?.first else {
                return
            }
            print(placemark.name)
            // 200 Queen St
            print(placemark.qualifiedName)
            // 200 Queen St, Saint John, New Brunswick E2L 2X1, Canada
            
            //search result
            let thepoints = placemark.location.coordinate
            
            self.destinationGlobal = thepoints
            print("\(thepoints.latitude), \(thepoints.longitude)")
            //after finishe search go the the result place
            self.zoomIntoResult(self.mapView, placemark)
        }
            self.searchFlag = true
    }
    
    func searchingAlert(){
        let alertController = UIAlertController(title: "Where do you want to go?", message: "Please input your destination:", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Search", style: .default) { (_) in
            if let field = alertController.textFields?[0] {
                // store your data
                self.searchingAndConvert(field.text!)
            } else {
                // user did not fill field
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            if let annotations = self.mapView.annotations {
                self.mapView.removeAnnotations(annotations)
            }
            self.destinationGlobal = nil
        }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Address/Postol code"
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    func afterSearching(){
        let alertController = UIAlertController(title: "Is this the correct address?", message: "If not, try to use postal code", preferredStyle: .actionSheet)
        let confirmAction = UIAlertAction(title: "Go!", style: .destructive) { (_) in
            self.startRoute = true
            self.searchFlag = false
            self.drawRoute()
//            if let field = alertController.textFields?[0] {
//                // store your data
//                //self.searchingAndConvert(field.text!)
//            } else {
//                // user did not fill field
//            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            if let annotations = self.mapView.annotations {
                self.mapView.removeAnnotations(annotations)
                self.destinationGlobal = nil
            }
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    func stopAlert(){
        let alertController = UIAlertController(title: "Stop Current Trip ", message: "Do you want to stop?", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Stop", style: .destructive) { (_) in
            self.startRoute = false
            self.searchFlag = false
            if let annotations = self.mapView.annotations {
                self.mapView.removeAnnotations(annotations)
                self.destinationGlobal = nil
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    //drawing
    func drawRoute(){
        let locValue:CLLocationCoordinate2D = locationManager.location!.coordinate
        guard destinationGlobal != nil else {
            
            return
        }
        let waypoints = [
            Waypoint(coordinate: locValue, name: "Mapbox"),
            Waypoint(coordinate: destinationGlobal, name: "Science World"),
            ]
        let options = RouteOptions(waypoints: waypoints, profileIdentifier: .automobileAvoidingTraffic)
        options.includesSteps = true
        
        let task = directions.calculate(options) { (waypoints, routes, error) in
            guard error == nil else {
                print("Error calculating directions: \(error!)")
                return
            }
            
            if let route = routes?.first, let leg = route.legs.first {
                print("Route via \(leg):")
                
                let travelTimeFormatter = DateComponentsFormatter()
                travelTimeFormatter.unitsStyle = .short
                let formattedTravelTime = travelTimeFormatter.string(from: route.expectedTravelTime)
                
                print("Distance: \(route.distance)m; ETA: \(formattedTravelTime!)")
                
                for step in leg.steps {
                    if let left = step.maneuverDirection {
                        if ("\(left)" == "left" || "\(left)" == "sharp left") {
                            self.leftTurningPoints.append(step.maneuverLocation)
                            print("\(step.instructions)")
                            // Turn Direction. Left Right Straight
                            //print("ManeuverDirection: \(step.maneuverDirection!)")
                            // Turn, Depart, Arrive, End of Road (hit T intersection)
                            print("ManeuverType: \(step.maneuverType!)")
                            // Maneuver location
                            print("ManeuverLocation: \(step.maneuverLocation.latitude)  \(step.maneuverLocation.longitude)")
                            print("\(step.intersections![step.intersections!.count-1].location.latitude)    \(step.intersections![step.intersections!.count-1].location.longitude)")
                            //print("\(legsteps["intersection"][legsteps["intersection"].count-1]["location"][0])   \(legsteps["intersection"][legsteps["intersection"].count-1]["location"][1])")
                            print("— \(step.distance)m —")
                            
                            let point = MGLPointAnnotation()
                            point.coordinate = step.maneuverLocation
                            point.title = "LeftTurn!"
                            point.subtitle = "\(step.maneuverLocation.latitude)    \(step.maneuverLocation.longitude)"
                            self.mapView.addAnnotation(point)
                        }
                    }
                }
                
                if route.coordinateCount > 0 {
                    for p in self.leftTurningPoints {
                        print("\(p.latitude)   \(p.longitude)")
                    }
                    // Convert the route’s coordinates into a polyline.
                    var routeCoordinates = route.coordinates!
                    let routeLine = MGLPolyline(coordinates: &routeCoordinates, count: route.coordinateCount)
                    
                    // Add the polyline to the map and fit the viewport to the polyline.
                    self.mapView.addAnnotation(routeLine)
                    self.mapView.setVisibleCoordinates(&routeCoordinates, count: route.coordinateCount, edgePadding: .zero, animated: true)
                }
            }
        }
    }
}
