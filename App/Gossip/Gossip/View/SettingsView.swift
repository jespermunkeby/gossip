//
//  SettingsView.swift
//  Gossip
//
//  Created by Abbas Alubeid on 2023-05-02.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var body: some View {
        ZStack {
            VStack {
                HeaderView(showSettings: .constant(false))

                VStack(alignment: .leading, spacing: 30) {
                    Group {
                        Text("To authenticate yourself, please follow the steps below:")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        Text("1. Connect to the Hub wifi.")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        Text("2. After connecting, click the link below to authenticate.")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        Link(destination: URL(string: "https://www.example.com")!) {
                            HStack {
                                Text("Authenticate")
                                    .underline()
                                    .foregroundColor(.blue)
                            }
                            .font(.title2)
                            .padding(.horizontal)
                        }
                    }
                    Spacer()
                }
                .padding(.top)
            }
            .navigationBarBackButtonHidden(true)
            
            Spacer()
            
            HStack {
                Spacer()
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "arrow.uturn.left")
                            .imageScale(.large)
                            .scaleEffect(1.5, anchor: .center)
                    }
                    .padding(25)
                    .background(Color(red: 0.7960784314, green: 0.8980392157, blue: 0.8745098039))
                    .foregroundColor(.black)
                    .clipShape(Circle())
                }
                .padding()
            }
        }
    }
}


