//
//  BLEViewModelExtension+SwiftUIView.swift
//  BLEDemo
//

import SwiftUI
import CoreBluetooth

//MARK: - Navigation Items
extension ListView {
    func navigateToDetailView(isDetailViewLinkActive: Binding<Bool>) -> some View {
        let navigateToDetailView =
            NavigationLink("",
                           destination: DetailView(),
                           isActive: isDetailViewLinkActive).frame(width: 0, height: 0)
        return navigateToDetailView
    }
}
