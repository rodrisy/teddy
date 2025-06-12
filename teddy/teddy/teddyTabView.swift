//
//  teddyTabView.swift
//  teddy
//
//  Created by Rodrigo Sánchez Yuste on 9/6/25.
//

import SwiftUI

struct teddyTabView: View {
    @EnvironmentObject var manager: HealthManager
    @State var selectedTab = "Home"
    
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tag("Home")
                .tabItem {
                    Image(systemName: "house")
                }
                .environmentObject(manager)
            
            SleepView()
                .tag("Sleep")
                .tabItem {
                    Image(systemName: "bed.double.fill")
                }
            
            ContentView()
                .tag("Content")
                .tabItem {
                    Image(systemName: "person")
                }
            
            
        }
    }
}

#Preview {
    teddyTabView()
}
