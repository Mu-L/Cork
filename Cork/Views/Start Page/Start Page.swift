//
//  Start Page.swift
//  Cork
//
//  Created by David Bureš on 10.02.2023.
//

import CorkShared
import SwiftUI

struct StartPage: View
{
    enum StartPageStage
    {
        case loading, showingBrewOverview
    }

    @EnvironmentObject var brewData: BrewDataStorage
    @EnvironmentObject var availableTaps: TapTracker

    @EnvironmentObject var cachedPackagesTracker: CachedPackagesTracker

    @EnvironmentObject var appState: AppState

    @EnvironmentObject var updateProgressTracker: UpdateProgressTracker
    @EnvironmentObject var outdatedPackageTracker: OutdatedPackageTracker

    @State private var isOutdatedPackageDropdownExpanded: Bool = false

    @State private var dragOver: Bool = false

    var startPageStage: StartPageStage
    {
        if appState.isLoadingFormulae && appState.isLoadingCasks || appState.isLoadingTaps
        {
            return .loading
        }
        else
        {
            return .showingBrewOverview
        }
    }

    var shouldShowCachedDownloadsGraph: Bool
    {
        if cachedPackagesTracker.cachedDownloadsSize == 0
        {
            return false
        }
        else
        {
            return true
        }
    }

    var body: some View
    {
        VStack
        {
            switch startPageStage
            {
            case .loading:
                ProgressView("start-page.loading")
                    .transition(.push(from: .top))
            case .showingBrewOverview:
                FullSizeGroupedForm
                {
                    Section
                    {
                        OutdatedPackagesBox(
                            isOutdatedPackageDropdownExpanded: $isOutdatedPackageDropdownExpanded
                        )
                    } header: {
                        HStack(alignment: .center, spacing: 10)
                        {
                            Text("start-page.status")
                                .font(.title)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

                            /*
                             Button
                             {
                                 NSWorkspace.shared.open(URL(string: "https://blog.corkmac.app/p/upcoming-changes-to-the-install-process")!)
                             } label: {
                                 Text("start-page.upcoming-changes")
                                     .padding(.horizontal, 6)
                                     .padding(.vertical, 1)
                                     .foregroundColor(.white)
                                     .background(.blue)
                                     .clipShape(.capsule)
                             }
                             .buttonStyle(.plain)
                              */
                        }
                    }

                    if !brewData.unsuccessfullyLoadedFormulaeErrors.isEmpty || !brewData.unsuccessfullyLoadedCasksErrors.isEmpty
                    {
                        Section
                        {
                            LoadingErrorsBox()
                        }
                    }

                    Section
                    {
                        PackageAndTapOverviewBox()
                    }

                    Section
                    {
                        AnalyticsStatusBox()
                    }

                    if shouldShowCachedDownloadsGraph
                    {
                        Section
                        {
                            CachedDownloadsFolderInfoBox()
                        }
                    }
                }
                .transition(.push(from: .top))

                ButtonBottomRow
                {
                    Spacer()

                    Button
                    {
                        AppConstants.shared.logger.info("Would perform maintenance")
                        appState.showSheet(ofType: .maintenance(fastCacheDeletion: false))
                    } label: {
                        Text("start-page.open-maintenance")
                    }
                }
                .transition(.push(from: .top))
            }
        }
        .onAppear
        {
            AppConstants.shared.logger.debug("Cached downloads path: \(AppConstants.shared.brewCachedDownloadsPath)")
        }
        .onDrop(of: [.fileURL], isTargeted: $dragOver)
        { providers -> Bool in
            providers.first?.loadDataRepresentation(forTypeIdentifier: "public.file-url", completionHandler: { data, _ in
                if let data = data, let path = String(data: data, encoding: .utf8), let url = URL(string: path as String)
                {
                    if url.pathExtension == "brewbak" || url.pathExtension.isEmpty
                    {
                        AppConstants.shared.logger.debug("Correct File Format")

                        Task
                        { @MainActor in
                            try await importBrewfile(from: url, appState: appState, brewData: brewData, cachedPackagesTracker: cachedPackagesTracker)
                        }
                    }
                    else
                    {
                        AppConstants.shared.logger.error("Incorrect file format")
                    }
                }
            })
            return true
        }
        .overlay
        {
            if dragOver
            {
                ZStack(alignment: .center)
                {
                    Rectangle()
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .foregroundColor(Color(nsColor: .gridColor))

                    VStack(alignment: .center, spacing: 10)
                    {
                        Image(systemName: "square.and.arrow.down")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100)

                        Text("navigation.menu.import-export.import-brewfile")
                            .font(.largeTitle)
                    }
                    .foregroundColor(Color(nsColor: .secondaryLabelColor))
                }
            }
        }
        .animation(.easeInOut, value: dragOver)
        .animation(appState.enableExtraAnimations ? .interpolatingSpring : .none, value: startPageStage)
    }
}
