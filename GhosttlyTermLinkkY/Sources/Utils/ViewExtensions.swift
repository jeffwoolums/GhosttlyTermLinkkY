//
//  ViewExtensions.swift
//  GhosttlyTermLinkkY
//
//  Cross-platform view modifiers
//

import SwiftUI

extension View {
    /// Cross-platform navigation bar title display mode
    @ViewBuilder
    func navigationBarTitleDisplayModeInline() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}
