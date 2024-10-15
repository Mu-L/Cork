//
//  Menu Bar - Package Updating.swift
//  Cork
//
//  Created by David Bureš on 30.03.2024.
//

import SwiftUI

struct MenuBar_PackageUpdating: View
{
    @Environment(AppState.self) var appState: AppState
    @EnvironmentObject var outdatedPackageTracker: OutdatedPackageTracker

    var body: some View
    {
        if appState.isCheckingForPackageUpdates
        {
            Text("start-page.updates.loading")
                .disabled(true)
        }
        else
        {
            if !outdatedPackageTracker.displayableOutdatedPackages.isEmpty
            {
                if !appState.isShowingUpdateSheet
                {
                    Menu
                    {
                        ForEach(outdatedPackageTracker.displayableOutdatedPackages.sorted(by: { $0.package.installedOn! < $1.package.installedOn! }))
                        { outdatedPackage in
                            SanitizedPackageName(packageName: outdatedPackage.package.name, shouldShowVersion: false)
                        }
                    } label: {
                        Text("notification.outdated-packages-found.body-\(outdatedPackageTracker.displayableOutdatedPackages.count)")
                    }
                    
                    Button("navigation.upgrade-packages")
                    {
                        switchCorkToForeground()
                        appState.isShowingUpdateSheet = true
                    }
                }
                else
                {
                    Text("update-packages.detail-stage.pouring")
                }
                
            }
            else
            {
                Text("update-packages.no-updates.description")
            }
        }
    }
}
