import Foundation
import XCTest
import Combine

public extension XCTestCase {

    ///
    /// Helper function to asyncronously wait for publisher values in tests.
    ///
    /// # Example:
    /// ```
    /// async let expectingValue = waitForPublisherExpectations(myPublisher.dropFirst().first())
    /// let value = try? await expectingValue
    /// XCTAssertNotNil(value)
    /// ```
    ///
    /// idea from https://www.swiftbysundell.com/articles/unit-testing-combine-based-swift-code/
    ///
    //@MainActor
    func waitForPublisherExpectations<T: Publisher>(_ publisher: T,
                                                    timeout: TimeInterval = 10,
                                                    file: StaticString = #file,
                                                    line: UInt = #line
    ) async throws -> T.Output {
        // This time, we use Swift's Result type to keep track
        // of the result of our Combine pipeline:
        var result: Result<T.Output, Error>?
        let expectation = expectation(description: "Awaiting publisher")
        
        let cancellable = publisher.sink(
            receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    result = .failure(error)
                case .finished:
                    break
                }
                
                expectation.fulfill()
            },
            receiveValue: { value in
                result = .success(value)
            }
        )
        
        // Just like before, we await the expectation that we
        // created at the top of our test, and once done, we
        // also cancel our cancellable to avoid getting any
        // unused variable warnings:
        await waitForExpectations(timeout: timeout)
        cancellable.cancel()
        
        // Here we pass the original file and line number that
        // our utility was called at, to tell XCTest to report
        // any encountered errors at that original call site:
        let unwrappedResult = try XCTUnwrap(
            result,
            "Awaited publisher did not produce any output",
            file: file,
            line: line
        )
        
        return try unwrappedResult.get()
    }
    
}
