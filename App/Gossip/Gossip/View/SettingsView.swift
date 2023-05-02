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
            NavigationView {
                VStack(alignment: .leading, spacing: 30) {
                    Group {
                        Text("To authenticate yourself, please follow the steps below:")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        Text("1. Connect to the Hub wifi.")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.black)
                            .padding(.horizontal)
                        
                        Text("2. After connecting, click the link below to authenticate.")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.black)
                            .padding(.horizontal)
                        
                        Link(destination: URL(string: "https://www.example.com")!) {
                            HStack {
                                Text("Authenticate")
                                    .underline()
                                    .foregroundColor(.blue)
                            }
                            .font(.title2)
                            .foregroundColor(.black)
                            .padding(.horizontal)
                        }
                    }
                    Spacer()
                }
                .padding(.top)
                
            }.navigationBarBackButtonHidden(true) 
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Back")
                            .font(.title)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding()
                }
            }
        }
    }
}


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
