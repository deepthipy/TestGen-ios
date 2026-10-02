import Foundation

struct GeneratedTestSuite: Codable, Equatable {
    let sourceType: String
    let summary: String
    let tests: [GeneratedTest]
}

struct GeneratedTest: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let purpose: String
    let code: String

    init(
        id: UUID = UUID(),
        name: String,
        purpose: String,
        code: String
    ) {
        self.id = id
        self.name = name
        self.purpose = purpose
        self.code = code
    }
}
