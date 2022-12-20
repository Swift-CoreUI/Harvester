import XCTest
import XCTestHarvester
import UIKit
import Combine
@testable import Harvester

final class AttachChildTests: XCTestCase {
    private class Parent: UIViewController {}
    private class Loader: UIViewController {}

    func testAttachChild() {
        let vc1 = Parent()

        var cancellables: Set<AnyCancellable> = []

        let isLoading = PassthroughSubject<Bool, Never>()

        isLoading.attachLoader(Loader(), to: vc1)
            .store(in: &cancellables)

        XCTAssertEqual(vc1.children.count, 0)
        XCTAssertFalse(vc1.isModalInPresentation)
        XCTAssertFalse(vc1.navigationItem.hidesBackButton)

        isLoading.send(false)
        XCTAssertEqual(vc1.children.count, 0)

        isLoading.send(true)
        XCTAssertEqual(vc1.children.count, 1)
        XCTAssertTrue(vc1.isModalInPresentation)
        XCTAssertTrue(vc1.navigationItem.hidesBackButton)

        isLoading.send(true)
        XCTAssertEqual(vc1.children.count, 1)

        cancellables = []
        XCTAssertEqual(vc1.children.count, 0)

        isLoading.send(true)
        XCTAssertEqual(vc1.children.count, 0)
    }

    func testAttachChildToMultipleParents() {
        let vc1 = Parent()
        let vc2 = Parent()
        let loader = Loader()

        let isLoading = PassthroughSubject<Bool, Never>()

        let cancellable1 = isLoading.attachLoader(loader, to: vc1)

        let cancellable2 = isLoading.attachLoader(loader, to: vc2)

        XCTAssertEqual(vc1.children.count, 0)
        XCTAssertEqual(vc2.children.count, 0)

        isLoading.send(true)
        // only one parent will have loader attached, but we can't know which one exactly
        XCTAssertEqual(vc1.children.count + vc2.children.count, 1)

        cancellable1.cancel()

        isLoading.send(true)
        XCTAssertEqual(vc1.children.count, 0)
        XCTAssertEqual(vc2.children.count, 1)

        cancellable2.cancel()
        isLoading.send(true)
        XCTAssertEqual(vc1.children.count, 0)
        XCTAssertEqual(vc2.children.count, 0)
    }
}
