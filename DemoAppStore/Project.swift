import ProjectDescription

let project = Project(
    name: "DemoAppStore",
    targets: [
        // Core
        .target(
            name: "Core",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.DemoAppStore.Core",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .default,
            buildableFolders: [
                "DemoAppStore/Core/Sources"
            ],
            dependencies: []
        ),
        // Domain
        .target(
            name: "Domain",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.DemoAppStore.Domain",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .default,
            buildableFolders: [
                "DemoAppStore/Domain/Sources"
            ],
            dependencies: [
                .target(name: "Core")
            ]
        ),
        // Data
        .target(
            name: "Data",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.DemoAppStore.Data",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .default,
            buildableFolders: [
                "DemoAppStore/Data/Sources"
            ],
            dependencies: [
                .target(name: "Domain"),
                .target(name: "Core")
            ]
        ),
        // Presentation - Home Feature
        .target(
            name: "PresentationHome",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.DemoAppStore.PresentationHome",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .default,
            buildableFolders: [
                "DemoAppStore/Presentation/Home/Sources"
            ],
            dependencies: [
                .target(name: "Domain"),
                .target(name: "Core")
            ]
        ),
        // Presentation - Detail Feature
        .target(
            name: "PresentationDetail",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.DemoAppStore.PresentationDetail",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .default,
            buildableFolders: [
                "DemoAppStore/Presentation/Detail/Sources"
            ],
            dependencies: [
                .target(name: "Domain"),
                .target(name: "Core")
            ]
        ),
        // Main App
        .target(
            name: "DemoAppStore",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.tuist.DemoAppStore",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": ""
                    ]
                ]
            ),
            buildableFolders: [
                "DemoAppStore/App/Sources",
                "DemoAppStore/App/Resources"
            ],
            dependencies: [
                .target(name: "PresentationHome"),
                .target(name: "PresentationDetail"),
                .target(name: "Data")
            ]
        ),
        // Feature App - Home
        .target(
            name: "HomeApp",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.tuist.DemoAppStore.HomeApp",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .default,
            buildableFolders: [
                "DemoAppStore/FeatureApps/HomeApp/Sources",
                "DemoAppStore/FeatureApps/HomeApp/Resources"
            ],
            dependencies: [
                .target(name: "PresentationHome"),
                .target(name: "Data")
            ]
        ),
        // Feature App - Detail
        .target(
            name: "DetailApp",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.tuist.DemoAppStore.DetailApp",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .default,
            buildableFolders: [
                "DemoAppStore/FeatureApps/DetailApp/Sources",
                "DemoAppStore/FeatureApps/DetailApp/Resources"
            ],
            dependencies: [
                .target(name: "PresentationDetail"),
                .target(name: "Data")
            ]
        ),
        // Tests
        .target(
            name: "DomainTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.DemoAppStore.DomainTests",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .default,
            buildableFolders: [
                "DemoAppStore/Tests/Domain"
            ],
            dependencies: [
                .target(name: "Domain")
            ]
        ),
        .target(
            name: "DataTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.DemoAppStore.DataTests",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .default,
            buildableFolders: [
                "DemoAppStore/Tests/Data"
            ],
            dependencies: [
                .target(name: "Data")
            ]
        ),
        .target(
            name: "PresentationHomeTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.DemoAppStore.PresentationHomeTests",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .default,
            buildableFolders: [
                "DemoAppStore/Tests/Presentation/Home"
            ],
            dependencies: [
                .target(name: "PresentationHome")
            ]
        )
    ]
)
