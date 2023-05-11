//
//  MapManager.swift
//  Gossip
//
//  Created by Abbas Alubeid on 2023-05-09.
//

import CoreLocation
import MapKit




// CLLocationManagerDelegate makes it possible to listen for changes in auth settings
class MapManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    struct MapDetails {
        static let startingLocation = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        static let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    }
    // @Published makes the UI connected to it update as soon as is updates
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var region = MKCoordinateRegion(center: MapDetails.startingLocation, span: MapDetails.defaultSpan)
    static let shared = MapManager()

    //Optional since it can be turned off by user
    var locationManager: CLLocationManager?

    func isLocationEnabled(){
        if CLLocationManager.locationServicesEnabled() {
            // Initialize a location manager if service is enabled by user
            locationManager = CLLocationManager()
            // To get access to locationManagerDidChangeAuthorization
            locationManager!.delegate = self
            locationManager!.startUpdatingLocation()
        }
        else {
            print("User has not enabled location services")
        }
    }

    // Handle different cases of location permission by user
    private func checkLocationAuth(){
        guard let locationManager = locationManager else { return }

        switch locationManager.authorizationStatus {
        // No permission, ask for it
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            region.center = MapDetails.startingLocation
            print("We are asking for access")
        case .restricted, .denied:
            print("Access denied or restricted")
            region.center = MapDetails.startingLocation
        // We have permission
        case .authorizedAlways, .authorizedWhenInUse:
            // Do nothing here, didUpdateLocations function will handle it
            print("We have access")
            break
        @unknown default:
            break
        }
    }

    // This function gets called when a CLLocationManager is created or when it changes (when user changes location settings)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuth()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location.coordinate
    }

    
    func getDeviceCurrentLocation() -> CLLocationCoordinate2D? {
        guard let location = locationManager?.location else {
            return nil
        }
        let originalLat = location.coordinate.latitude
        let originalLon = location.coordinate.longitude

        let truncatedLat = Double(Int(originalLat*10000))/10000
        let truncatedLon = Double(Int(originalLon*10000))/10000

        return CLLocationCoordinate2D(latitude: originalLat, longitude: originalLon)
    }




}

