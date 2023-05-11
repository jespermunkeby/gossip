//
//  mapView.swift
//  Gossip
//
//  Created by Abbas Alubeid on 2023-05-08.
//

import MapKit
import SwiftUI

struct mapView: View {
    @StateObject private var mapManager = MapManager.shared
    var messages: [FeedCard]
    @State private var selectedAnnotation: GroupedMessageAnnotation? = nil

    var groupedMessages: [GroupedMessageAnnotation] {
        let grouped = Dictionary(grouping: messages) {
            CoordinateKey(latitude: $0.latitude, longitude: $0.longitude)
        }
        return grouped.map { (key, messages) in
            GroupedMessageAnnotation(
                messages: messages,
                coordinate: CLLocationCoordinate2D(latitude: key.latitude, longitude: key.longitude)
            )
        }
    }

    var body: some View {
        ZStack {
            Map(coordinateRegion: $mapManager.region, showsUserLocation: true, annotationItems: groupedMessages) { annotation in
                MapAnnotation(coordinate: annotation.coordinate) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.red)
                        .scaleEffect(1.1)
                        .onTapGesture {
                            self.selectedAnnotation = annotation
                        }
                }
            }
            .ignoresSafeArea()
            .onAppear {
                mapManager.isLocationEnabled()
            }
            
            if let selectedAnnotation = selectedAnnotation {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            self.selectedAnnotation = nil
                        }) {
                            Image(systemName: "xmark.circle")
                                .font(.largeTitle)
                                .padding()
                                .accentColor(Color(#colorLiteral(red: 0.7960784314, green: 0.8980392157, blue: 0.8745098039, alpha: 1)))
                        }
                    }
                    Text("Messages from location: (\(selectedAnnotation.coordinate.latitude), \(selectedAnnotation.coordinate.longitude))")
                        .font(.headline)
                        .padding(.bottom, 10)
                    ScrollView {
                        ForEach(selectedAnnotation.messages.indices, id: \.self) { index in
                            FeedCardView(post: selectedAnnotation.messages[index])
                            .padding()
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(10)
                .transition(.move(edge: .bottom))
            }
        }
    }
}

struct GroupedMessageAnnotation: Identifiable {
    let id = UUID()
    let messages: [FeedCard]
    let coordinate: CLLocationCoordinate2D
}

struct CoordinateKey: Hashable {
    var latitude: Double
    var longitude: Double
}
