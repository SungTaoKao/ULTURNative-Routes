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


class ViewController: UIViewController, CLLocationManagerDelegate, MGLMapViewDelegate
{
    
    let directions = Directions.shared
    var locationManager = CLLocationManager()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = CLLocationManager()
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        let manager = CLLocationManager()
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate

        let mapView = MGLMapView(frame: view.bounds, styleURL: MGLStyle.darkStyleURL())
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.setCenter(CLLocationCoordinate2D(latitude: locValue.latitude, longitude: locValue.longitude), zoomLevel: 15, animated: false)
        view.addSubview(mapView)
        
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        
        // Set the map view's delegate
        mapView.delegate = self
        // Allow the map view to display the user's location
        mapView.showsUserLocation = true
        
        let waypoints = [
            Waypoint(coordinate: locValue, name: "Mapbox"),
            Waypoint(coordinate: CLLocationCoordinate2D(latitude: 38.8977, longitude: -77.0365), name: "White House"),
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
                    if ("\(step.maneuverDirection!)" == "left" || "\(step.maneuverDirection!)" == "sharp left") {
                        print("\(step.instructions)")
                        print("\(step.initialHeading!) \(step.finalHeading!)")
                        // Turn Direction. Left Right Straight
                        print("ManeuverDirection: \(step.maneuverDirection!)")
                        // Turn, Depart, Arrive, End of Road (hit T intersection)
                        print("ManeuverType: \(step.maneuverType!)")
                        // Maneuver location
                        print("ManeuverLocation: \(step.maneuverLocation.latitude)  \(step.maneuverLocation.longitude)")
                        print("\(step.intersections![step.intersections!.count-1].location.latitude)    \(step.intersections![step.intersections!.count-1].location.longitude)")
                        //print("\(legsteps["intersection"][legsteps["intersection"].count-1]["location"][0])   \(legsteps["intersection"][legsteps["intersection"].count-1]["location"][1])")
                        print("— \(step.distance)m —")
                        
                        let point = MGLPointAnnotation()
                        point.coordinate = step.maneuverLocation
                        point.title = "Left Turn Point"
                        point.subtitle = "\(step.maneuverLocation.latitude)    \(step.maneuverLocation.longitude)"
                        mapView.addAnnotation(point)
                    }
                    
                }
                
                if route.coordinateCount > 0 {
                    // Convert the route’s coordinates into a polyline.
                    var routeCoordinates = route.coordinates!
                    let routeLine = MGLPolyline(coordinates: &routeCoordinates, count: route.coordinateCount)
                    
                    // Add the polyline to the map and fit the viewport to the polyline.
                    mapView.addAnnotation(routeLine)
                    mapView.setVisibleCoordinates(&routeCoordinates, count: route.coordinateCount, edgePadding: .zero, animated: true)
                }
            }
        }
        
        
    }
    //continue update current location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        print("Current Speed:\(manager.location!.speed)")
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
        let camera = MGLMapCamera(lookingAtCenter: annotation.coordinate, fromDistance: 4000, pitch: 0, heading: 0)
        mapView.setCamera(camera, animated: true)
    }
}

