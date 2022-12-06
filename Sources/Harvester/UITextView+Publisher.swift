import UIKit
import Combine

extension UITextView {

    ///
    /// Continously publishes typed text from UITextView
    /// 
    var textPublisher: AnyPublisher<String, Never> {
        NotificationCenter.default
            .publisher(for: Self.textDidChangeNotification, object: self)
            .compactMap { ($0.object as? Self)?.text }
            .eraseToAnyPublisher()
    }
    
}
