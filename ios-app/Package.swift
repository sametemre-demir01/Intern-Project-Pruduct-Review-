// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ProductReviewApp",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ProductReviewApp", targets: ["ProductReviewApp"])
    ],
    targets: [
        .executableTarget(
            name: "ProductReviewApp",
            path: "ProductReviewApp",
            sources: [
                "App/ProductReviewApp.swift",
                "Models/Product.swift",
                "Models/Review.swift",
                "Services/APIService.swift",
                "ViewModels/ProductDetailViewModel.swift",
                "ViewModels/ProductListViewModel.swift",
                "Views/ProductDetailView.swift",
                "Views/ProductListView.swift"
            ]
        )
    ]
)
