//
//  View+Extension.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/30/25.
//

import SwiftUI

/// Applies network connectivity monitoring and alert functionality to any SwiftUI view
extension View {
    func networkAlert() -> some View {
        self.modifier(NetworkAlertModifier())
    }
}
