import Combine

public extension Publisher where Failure == Never {

    ///
    /// The same as Publisher.assign(to:on:), but does not perform strong capturing of target object
    ///
    func assign<Root: AnyObject>(
        to keyPath: ReferenceWritableKeyPath<Root, Output>,
        onWeak object: Root)
    -> AnyCancellable {
       sink { [weak object] in
           object?[keyPath: keyPath] = $0
        }
    }

}
