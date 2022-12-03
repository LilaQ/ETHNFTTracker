//
//  ETHNFTTrackerApp.swift
//  ETHNFTTracker
//
//  Created by Jan on 10.11.22.
//

import Combine
import SwiftUI
import UserNotifications

@main
struct ETHNFTTrackerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ZStack {
              EmptyView()
            }
            .hidden()
          }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    var window: NSWindow!
    var popover = NSPopover.init()
    var statusBar: StatusBarController?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        // Create the SwiftUI view that provides the contents
        let contentView = ContentView()

        // Set the SwiftUI's ContentView to the Popover's ContentViewController
        popover.contentSize = NSSize(width: 420, height: 600)
        popover.behavior = NSPopover.Behavior.transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        //Initialising the status bar
        statusBar = StatusBarController.init(popover)
        NSApplication.shared.keyWindow?.close()
        
        //  no dock item / no menu bar
        NSApp.setActivationPolicy(.prohibited)
        
        URLCache.shared.memoryCapacity = 1_000_000_000 // ~50 MB memory space
        URLCache.shared.diskCapacity = 1_000_000_000 // ~1GB disk cache space
        
        //  request notification permission
        requestNotificationPermission()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, shouldPresent notification: UNMutableNotificationContent) -> Bool {
        return true
    }

    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization() { granted, error in
            if error != nil {
                print ("Request notifications permission Error");
            }
            if granted {
                print ("Notifications allowed")
            } else {
                print ("Notifications denied")
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationWillResignActive(_ notification: Notification) {
    }
    
}
