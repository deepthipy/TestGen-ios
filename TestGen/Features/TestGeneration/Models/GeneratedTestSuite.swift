import Foundation

struct GeneratedTestSuite: Decodable, Equatable {
    let sourceType: String
    let summary: String
    let tests: [GeneratedTest]
}

struct GeneratedTest: Identifiable, Decodable, Equatable {
    let id = UUID()
    let name: String
    let purpose: String
    let code: String

    private enum CodingKeys: String, CodingKey {
        case name
        case purpose
        case code
    }
}
