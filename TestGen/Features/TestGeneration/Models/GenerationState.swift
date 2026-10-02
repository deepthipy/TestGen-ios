import Foundation

enum GenerationState {
    case idle
    case loading
    case success(GeneratedTestSuite)
    case failure(String)
}
