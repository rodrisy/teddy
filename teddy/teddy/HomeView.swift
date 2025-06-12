//
//  HomeView.swift
//  teddy
//
//  Created by Rodrigo Sánchez Yuste on 9/6/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var manager: HealthManager
    var body: some View {
        ScrollView {
            VStack {
                LazyVGrid(columns: Array(repeating:GridItem(spacing: 20), count: 2)) {
                    ForEach(manager.activities.sorted(by: {$0.value.id < $1.value.id}), id: \.key) {
                        item in ActivityCard(activity: item.value)
                    }
                }
                .padding(.horizontal)
            }
            
            .onAppear{
                manager.fetchTodaySteps()
                manager.fetchTodayFlights()
            }
        }
        .refreshable {
                        manager.fetchTodaySteps()
                        manager.fetchTodayFlights()
                    }
    }
}

//#Preview {
//    HomeView()
//}
