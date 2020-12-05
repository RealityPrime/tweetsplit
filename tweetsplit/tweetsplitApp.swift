//
//  tweetsplitApp.swift
//  tweetsplit
//
//  Created by Avi Bar-Zeev on 12/3/20.
//

import SwiftUI

var tweets : Tweets = Tweets()

@main
struct tweetsplitApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView(tweets: tweets)
        }
    }
}
