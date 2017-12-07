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
    var startRoute: Bool!
    var leftTurningPoints = [CLLocationCoordinate2D]()

    
    @IBOutlet weak var speedButton: UIButton!
    @IBOutlet weak var mapviewlayer: UIView!
    
    @IBAction func searchAlert(_ sender: Any) {
        searchingAlert()
    }
    @IBAction func clickSpeed(_ sender: Any) {
        zoomIntopoint(mapView)
        //let searchingresults:String = "Bcit"
        //searchingAndConvert(searchingresults)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()


        mapView = MGLMapView(frame: view.bounds, styleURL: MGLStyle.darkStyleURL())
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let manager = CLLocationManager()
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        mapView.setCenter(CLLocationCoordinate2D(latitude: locValue.latitude, longitude: locValue.longitude), zoomLevel: 15, animated: true)
        mapviewlayer.addSubview(mapView)
        mapviewlayer.addSubview(speedButton)
        
        print("locations = \(locValue.latitude) \(locValue.longitude)")

        // Set the map view's delegate
        mapView.delegate = self
        // Allow the map view to display the user's location
        mapView.showsUserLocation = true
        let waypoints = [
            Waypoint(coordinate: locValue, name: "Mapbox"),
            Waypoint(coordinate: CLLocationCoordinate2D(latitude: 49.2353827, longitude: -123.0104543), name: "Science World"),
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
                            point.title = "Hello!"
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
    //continue update current location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        print("Current Speed:\(manager.location!.speed)")
        let speed = manager.location!.speed
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
        startRoute=false
        if (startRoute){
        let camera = MGLMapCamera(lookingAtCenter: manager.location!.coordinate, fromDistance: 1000, pitch: 0, heading: 0)
            mapView.setCamera(camera, animated: true)
        }
        //zoomIntopoint(mapView)
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
        afterSearching()
        let camera = MGLMapCamera(lookingAtCenter: annotation.coordinate, fromDistance: 1000, pitch: 0, heading: 0)
        mapView.setCamera(camera, animated: true)
    }
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        // Wait for the map to load before initiating the first camera movement.
        
        // Create a camera that rotates around the same center point, rotating 180°.
        // `fromDistance:` is meters above mean sea level that an eye would have to be in order to see what the map view is showing.
        let manager = CLLocationManager()
        
        let camera = MGLMapCamera(lookingAtCenter: manager.location!.coordinate, fromDistance: 1000, pitch: 0, heading: 0)

        // Animate the camera movement over 5 seconds.
        mapView.setCamera(camera, withDuration: 5, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
    }
    //this one called when user click the speed button on the screen
    func zoomIntopoint(_ mapView: MGLMapView){
        let manager = CLLocationManager()
        let camera = MGLMapCamera(lookingAtCenter: manager.location!.coordinate, fromDistance: 1000, pitch: 0, heading: 0)
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
            print("\(thepoints.latitude), \(thepoints.longitude)")
            //after finishe search go the the result place
            self.zoomIntoResult(self.mapView, placemark)
        }
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
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "address/postol code"
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    func afterSearching(){
        let alertController = UIAlertController(title: "Is this the correct address?", message: "If not, try to use postal code", preferredStyle: .actionSheet)
        let confirmAction = UIAlertAction(title: "Go!", style: .default) { (_) in
//            if let field = alertController.textFields?[0] {
//                // store your data
//                //self.searchingAndConvert(field.text!)
//            } else {
//                // user did not fill field
//            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
}

