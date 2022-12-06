import UIKit
import Combine

extension UITextField {

    ///
    /// Continously publishes typed text from UITextField
    /// 
    var textPublisher: AnyPublisher<String, Never> {
        NotificationCenter.default
            .publisher(for: Self.textDidChangeNotification, object: self)
            .compactMap { ($0.object as? Self)?.text }
            .eraseToAnyPublisher()
    }
    
}
