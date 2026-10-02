import Foundation

protocol AIProvider {
    func generateTests(
        for sourceCode: String
    ) async throws -> GeneratedTestSuite
}
