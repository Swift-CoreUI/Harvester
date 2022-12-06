import Combine

enum PublisherAsyncFirstError: Error {
    case noValue
}

public extension Publisher {

    ///
    /// Converts publisher to async function.
    /// Uses first publisher value as a return value.
    /// If publisher did not sent any value - throws `noValue` error
    /// 
    func asyncFirst() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            var isValueReceived = false

            cancellable = first()
                .sink { result in
                    switch result {
                    case .finished:
                        if !isValueReceived {
                            continuation.resume(throwing: PublisherAsyncFirstError.noValue)
                        }
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                } receiveValue: { value in
                    isValueReceived = true
                    continuation.resume(with: .success(value))
                }
        }
    }
    
}
