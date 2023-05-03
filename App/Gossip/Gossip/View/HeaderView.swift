//
//  HeaderView.swift
//  Gossip
//
//  Created by Abbas Alubeid on 2023-05-02.
//

import SwiftUI

struct HeaderView: View {
    @Binding var showSettings: Bool
    
    var body: some View {
        ZStack {
            Color(#colorLiteral(red: 0.7960784314, green: 0.8980392157, blue: 0.8745098039, alpha: 1))
                .edgesIgnoringSafeArea(.top)
            HStack {
                Image("logo_black")
                    .resizable()
                    .frame(width: 40, height: 40)
                
                Spacer()

                if showSettings {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .resizable()
                            .frame(width: 35, height: 35)
                            .accentColor(.black)
                    }
                }
            }
            .padding([.leading, .trailing, .bottom])

            Spacer(minLength: 0)
        }
        .frame(height: 60)
    }
}


struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        HeaderView(showSettings: .constant(true))
    }
}
