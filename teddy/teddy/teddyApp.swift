//
//  teddyApp.swift
//  teddy
//
//  Created by Rodrigo Sánchez Yuste on 9/6/25.
//

import SwiftUI

@main
struct teddyApp: App {
    @StateObject var manager = HealthManager()
    var body: some Scene {
        WindowGroup {
            teddyTabView()
                .environmentObject(manager)
        }
    }
}
