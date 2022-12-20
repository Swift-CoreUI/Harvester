import UIKit
import Combine

extension Publisher where Output == Bool, Failure == Never {

    /// Most commonly used function
    /// used to attach loading view controller (controller with a spinner) to some container
    /// locks navigaion and dismiss gestures
    /// by default fills parent completely (padding = 0)
    public func attachLoader(_ child: UIViewController, to parent: UIViewController, padding: CGFloat = 0) -> AnyCancellable {
        return attachChild(child, to: parent, shouldLockParentNavigation: true, padding: padding)
    }

    /// More flexible functions for better control (navigation lock can be customized, insets/padding can be customized)
    public func attachChild(_ child: UIViewController,
                            to parent: UIViewController,
                            shouldLockParentNavigation: Bool = false,
                            padding: CGFloat = 0
    ) -> AnyCancellable {
        return attachChild(child, to: parent,
                           shouldLockParentNavigation: shouldLockParentNavigation,
                           UIEdgeInsets(top: padding, left: padding, bottom: -padding, right: -padding))
    }

    public func attachChild(_ child: UIViewController,
                            to parent: UIViewController,
                            shouldLockParentNavigation: Bool = false,
                            _ insets: UIEdgeInsets
    ) -> AnyCancellable {
        let subscriber = Subscribers.ChildViewController(child, for: parent, lockNavigation: shouldLockParentNavigation, insets)
        subscribe(subscriber)
        return AnyCancellable(subscriber)
    }
}


///
/// Attaching/detaching child view controller controlled by Bool value from Publisher/Subject.
/// If value is `true` child controller will be added, if `false` - removed.
///
/// Usually is used to block UI in some container (or full screen) and/or show some loader.
///
/// Can block navigation and dismiss gestures (optionally).
/// Child can be added with padding or with custom insets.
///
/// Performs attaching in main thread, there is no need to additionaly wrap publisher with receive(on:)
///
/// NB: Strongly captures reference to child view controller!
/// There is no need to keep an additional reference to child controller somewhere else.
///
/// # Example:
/// ```
/// // somewhere in ViewModel:
/// struct MyViewModel {
///     let isLoading = PassthroughSubject<Bool>()
///
///     func startDownloading() {
///         isLoading.send(true) // shows loader in UI
///
///         // do actual loading synchronously or asynchronously
///         // ...
///
///         isLoading.send(false) // when download was finished notify UI and hide loader
///     }
/// }
///
/// // somewhere in ViewController:
/// class MyViewController: UIViewController {
///     private let viewModel: MyViewModel
///
///     override func viewDidLoad() {
///         // ...
///
///         viewModel.isLoading
///             .attachLoader(MyLoadingViewController(...), to: self)
///             .store(in: &cancellables)
///     }
///
///     func downloadButtonPressed() {
///         viewModel.startDownloading() // will completely fill MyViewController with MyLoadingViewController and start download
///     }
/// }
/// ```
extension Subscribers {

    public final class ChildViewController: Subscriber, Cancellable {
        public typealias Input = Bool
        public typealias Failure = Never

        private weak var parentViewController: UIViewController?
        private let childViewController: UIViewController
        private let childInsets: UIEdgeInsets
        private let shouldLockNavigation: Bool
        private var subscription: Subscription?

        public init(_ child: UIViewController, for parent: UIViewController, lockNavigation: Bool = true, _ insets: UIEdgeInsets) {
            self.childViewController = child
            self.childInsets = insets
            self.parentViewController = parent
            self.shouldLockNavigation = lockNavigation
        }

        public convenience init(_ child: UIViewController, for parent: UIViewController, lockNavigation: Bool = true, padding: CGFloat) {
            self.init(child, for: parent, lockNavigation: lockNavigation, UIEdgeInsets(top: padding, left: padding, bottom: -padding, right: -padding))
        }

        public func receive(subscription: Subscription) {
            subscription.request(.unlimited)
            self.subscription = subscription
        }

        @MainActor
        public func receive(_ isLoading: Bool) -> Subscribers.Demand {
            if isLoading {
                lock(true)
                attach()
            } else {
                detach()
                lock(false)
            }
            return .none
        }

        @MainActor
        public func receive(completion: Subscribers.Completion<Never>) {
            detach()
            lock(false)
        }

        @MainActor
        public func cancel() {
            detach()
            lock(false)

            subscription?.cancel()
        }

        @MainActor
        private func lock(_ isLocked: Bool) {
            guard shouldLockNavigation, let parentViewController = parentViewController else { return }

            parentViewController.isModalInPresentation = isLocked
            parentViewController.navigationItem.hidesBackButton = isLocked
        }

        @MainActor
        private func attach() {
            guard let parentViewController = parentViewController,
                  childViewController.parent != parentViewController
            else { return }

            parentViewController.addChild(childViewController)
            parentViewController.view.addSubview(childViewController.view)

            childViewController.view.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                childViewController.view.leadingAnchor.constraint(equalTo: parentViewController.view.leadingAnchor, constant: childInsets.left),
                childViewController.view.trailingAnchor.constraint(equalTo: parentViewController.view.trailingAnchor, constant: childInsets.right),
                childViewController.view.topAnchor.constraint(equalTo: parentViewController.view.topAnchor, constant: childInsets.top),
                childViewController.view.bottomAnchor.constraint(equalTo: parentViewController.view.bottomAnchor, constant: childInsets.bottom),
            ])

            childViewController.didMove(toParent: parentViewController)
        }

        @MainActor
        private func detach() {
            guard childViewController.parent != nil else { return }

            childViewController.willMove(toParent: nil)
            childViewController.view.removeFromSuperview()
            childViewController.removeFromParent()
        }
    }
}

