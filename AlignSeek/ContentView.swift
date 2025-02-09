//
//  ContentView.swift
//  AlignSeek
//

import SwiftUI

struct ContentView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    
    var body: some View {
        if isLoggedIn {
            HomeView()
        } else {
            LoginView(isLoggedIn: $isLoggedIn)
        }
    }
}

#Preview {
    ContentView()
}
