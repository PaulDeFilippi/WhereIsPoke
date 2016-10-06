//
//  ViewController.swift
//  WhereisPoke
//
//  Created by Paul Defilippi on 10/3/16.
//  Copyright © 2016 Paul Defilippi. All rights reserved.
//

import UIKit
import MapKit
import FirebaseDatabase

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    var mapHasCenteredOnce = false
    var geoFire: GeoFire!
    var geoFireReference: FIRDatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.userTrackingMode = MKUserTrackingMode.follow
        
        geoFireReference = FIRDatabase.database().reference()
        geoFire = GeoFire(firebaseRef: geoFireReference)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        locationAuthorizationSTatus()
        
    }
    
    func locationAuthorizationSTatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            mapView.showsUserLocation = true
            
        } else {
            
            locationManager.requestWhenInUseAuthorization()
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        if status == .authorizedWhenInUse {
            
            mapView.showsUserLocation = true
            
        }
    }
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 2000, 2000)
        
        mapView.setRegion(coordinateRegion, animated: true)
        
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        
        if let loc = userLocation.location {
            
            if !mapHasCenteredOnce {
                centerMapOnLocation(location: loc)
                mapHasCenteredOnce = true
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let annoIdentifier = "Pokemon"
        var annotationVIew: MKAnnotationView?
        
        if annotation.isKind(of: MKUserLocation.self) {
            annotationVIew = MKAnnotationView(annotation: annotation, reuseIdentifier: "User")
            annotationVIew?.image = UIImage(named: "ash")
        
        } else if let deqAnno = mapView.dequeueReusableAnnotationView(withIdentifier: annoIdentifier) {
            annotationVIew = deqAnno
            annotationVIew?.annotation = annotation
        
        } else {
            
            let av = MKAnnotationView(annotation: annotation, reuseIdentifier: annoIdentifier)
            av.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            annotationVIew = av
        }
        
        if let annotationVIew = annotationVIew, let anno = annotation as? PokeAnnotation {
            
            annotationVIew.canShowCallout = true
            annotationVIew.image = UIImage(named: "\(anno.pokemonNumber)")
            let btn = UIButton()
            btn.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            btn.setImage(UIImage(named: "map"), for: .normal)
            annotationVIew.rightCalloutAccessoryView = btn
        }
        
        return annotationVIew
        
    }
    
    func createSighting(forLocation location: CLLocation, withPokemon pokeId: Int) {
        
        geoFire.setLocation(location, forKey: "\(pokeId)")
        
    }
    
    func showSightingsOnMap(location: CLLocation) {
        let circleQuery = geoFire!.query(at: location, withRadius: 2.5)
        
        _ = circleQuery?.observe(
            GFEventType.keyEntered, with: { (key, location) in
                
                if let key = key, let location = location {
                    let anno = PokeAnnotation(coordinate: location.coordinate, pokemonNumber:
                    Int(key)!)
                    self.mapView.addAnnotation(anno)
                }
        })
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        
        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        
        showSightingsOnMap(location: loc)
        
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if let anno = view.annotation as? PokeAnnotation {
            let place = MKPlacemark(coordinate: anno.coordinate)
            let destination = MKMapItem(placemark: place)
            destination.name = "Pokemon Sighting"
            let regionDistance: CLLocationDistance = 1000
            let regionSpan = MKCoordinateRegionMakeWithDistance(anno.coordinate, regionDistance, regionDistance)
            
            let options = [MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center), MKLaunchOptionsMapSpanKey:  NSValue(mkCoordinateSpan: regionSpan.span), MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving] as [String : Any]
            
            MKMapItem.openMaps(with: [destination], launchOptions: options)
        }
    }

    @IBAction func spotRandomPokemon(_ sender: AnyObject) {
        
        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        
        let rand = arc4random_uniform(151) + 1
        createSighting(forLocation: loc, withPokemon: Int(rand))
        
    }

}

