//
//  NetworkMonitor.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/30/25.
//

import SwiftUI
import Network

/// Singleton class responsible for monitoring real-time network connectivity status throughout the application
/// Uses Apple's Network framework to detect connection changes and automatically notify the UI layer
///
/// Key responsibilities:
/// - Continuously monitor internet connectivity using NWPathMonitor
/// - Provide real-time updates to SwiftUI views through @Published properties
/// - Automatically trigger network alerts when connection is lost
/// - Handle connection state transitions and user notifications
///
/// This class is essential for Qaptain's Firebase operations, as all data synchronization requires internet connectivity
/// Used throughout the app to ensure users are informed about connectivity issues that may affect their experience
class NetworkMonitor: ObservableObject {
    
    // MARK: - Singleton Instance

    /// Shared singleton instance ensuring only one network monitor exists throughout the app lifecycle
    /// Prevents multiple monitors from conflicting and ensures consistent connectivity state
    static let shared = NetworkMonitor()
    
    // MARK: - Network Framework Properties

    /// Apple's Network framework monitor for detecting connectivity changes
    /// Monitors all available network paths (WiFi, Cellular, Ethernet)
    private let monitor = NWPathMonitor()
    
    /// Dedicated dispatch queue for network monitoring operations
    /// Prevents network operations from blocking the main thread
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    // MARK: - Published State Properties

    /// Current network connectivity status - observed by UI components
    /// True when device has internet access, false when disconnected
    @Published var isConnected = true
    
    /// Controls the display of network connectivity alerts
    /// Automatically set to true when connection is lost after being connected
    @Published var showNetworkAlert = false
    
    // MARK: - Initialization

    private init() {
        startMonitoring()
    }

    // MARK: - Network Monitoring Methods

    /// Initiates continuous network path monitoring using Apple's Network framework
    /// Sets up path update handler to respond to connectivity changes in real-time
    private func startMonitoring() {
        print("📡 NetworkMonitor: Starting continuous network path monitoring")
        print("📡 NetworkMonitor: Monitoring all network interfaces (WiFi, Cellular, Ethernet)")
        
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                
                let wasConnected = self?.isConnected ?? true
                self?.isConnected = path.status == .satisfied
                
                if wasConnected && !(self?.isConnected ?? true) {
                    self?.showNetworkAlert = true
                }
            }
        }
        
        // Start monitoring on dedicated background queue
        monitor.start(queue: queue)
    }
    
    // MARK: - Deinitialization
    
    /// Cleanup method to properly stop network monitoring when the monitor is deallocated
    /// Prevents memory leaks and ensures proper resource management
    deinit {
        monitor.cancel()
    }
}
