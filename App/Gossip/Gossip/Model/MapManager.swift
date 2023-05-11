//
//  MapManager.swift
//  Gossip
//
//  Created by Abbas Alubeid on 2023-05-09.
//

import CoreLocation
import MapKit


enum MapDetails {
    static let startingLocation = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    static let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
}

// CLLocationManagerDelegate makes it possible to listen for changes in auth settings
class MapManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    // @Published makes the UI connected to it update as soon as is updates
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
        region.center = location.coordinate
    }

    func getCurrentLocation() -> CLLocationCoordinate2D {
        let originalLat = region.center.latitude
        let originalLon = region.center.longitude

        let roundedLat = Double(round(10000*originalLat)/10000)
        let roundedLon = Double(round(10000*originalLon)/10000)

        return CLLocationCoordinate2D(latitude: roundedLat, longitude: roundedLon)
    }

}

