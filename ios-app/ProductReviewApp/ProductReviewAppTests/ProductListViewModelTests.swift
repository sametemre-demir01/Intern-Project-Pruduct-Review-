import XCTest
@testable import ProductReviewApp

final class ProductListViewModelTests: XCTestCase {
    func testInitialState() {
        let viewModel = ProductListViewModel()
        XCTAssertTrue(viewModel.products.isEmpty)
        XCTAssertTrue(viewModel.categories.isEmpty)
        XCTAssertEqual(viewModel.selectedCategory, "")
        XCTAssertEqual(viewModel.searchText, "")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.currentPage, 0)
        XCTAssertTrue(viewModel.hasMorePages)
    }
}
