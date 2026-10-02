import Foundation

struct MockAIProvider: AIProvider {

    func generateTests(
        for sourceCode: String
    ) async throws -> GeneratedTestSuite {

        try await Task.sleep(for: .seconds(1))

        let test = GeneratedTest(
            name: "testAddReturnsCorrectSum",
            purpose: "Verifies that Calculator.add returns the sum of two integers.",
            code: """
            func testAddReturnsCorrectSum() {
                let calculator = Calculator()

                let result = calculator.add(2, 3)

                XCTAssertEqual(result, 5)
            }
            """
        )

        return GeneratedTestSuite(
            sourceType: "Calculator",
            summary: "Generated unit tests for Calculator.",
            tests: [test]
        )
    }
}
