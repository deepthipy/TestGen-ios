import Foundation

struct GeminiAIProvider: AIProvider {

    private let apiKey: String
    private let session: URLSession

    init(
        apiKey: String,
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.session = session
    }

    func generateTests(
        for sourceCode: String
    ) async throws -> GeneratedTestSuite {

        let prompt = """
        You are an expert iOS engineer.

        Generate XCTest unit tests for the Swift source code below.

        Requirements:
        - Generate meaningful unit tests, not placeholders.
        - Include normal behaviour and relevant edge cases.
        - Use XCTest.
        - Do not include markdown code fences.
        - Return only valid JSON.

        Swift source code:

        \(sourceCode)
        """

        let responseText = try await send(prompt: prompt)

        return try JSONDecoder().decode(
            GeneratedTestSuite.self,
            from: Data(responseText.utf8)
        )
    }

    private func send(prompt: String) async throws -> String {

        let url = URL(
            string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent"
        )!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        request.setValue(
            apiKey,
            forHTTPHeaderField: "x-goog-api-key"
        )

        let testSchema = GeminiRequest.SchemaProperty.object(
            properties: [
                "name": .string,
                "purpose": .string,
                "code": .string
            ],
            required: [
                "name",
                "purpose",
                "code"
            ]
        )

        let responseSchema = GeminiRequest.SchemaProperty.object(
            properties: [
                "sourceType": .string,
                "summary": .string,
                "tests": .array(items: testSchema)
            ],
            required: [
                "sourceType",
                "summary",
                "tests"
            ]
        )

        let body = GeminiRequest(
            contents: [
                .init(
                    parts: [
                        .init(text: prompt)
                    ]
                )
            ],
            generationConfig: .init(
                responseMimeType: "application/json",
                responseSchema: responseSchema
            )
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            let responseBody = String(
                data: data,
                encoding: .utf8
            ) ?? "No response body"

            throw GeminiError.httpError(
                statusCode: httpResponse.statusCode,
                responseBody: responseBody
            )
        }

        let decodedResponse = try JSONDecoder().decode(
            GeminiResponse.self,
            from: data
        )

        guard let text = decodedResponse
            .candidates
            .first?
            .content
            .parts
            .first?
            .text else {
            throw GeminiError.missingContent
        }

        return text
    }
}

// MARK: - Request

private struct GeminiRequest: Encodable {

    let contents: [Content]
    let generationConfig: GenerationConfig

    struct Content: Encodable {
        let parts: [Part]
    }

    struct Part: Encodable {
        let text: String
    }

    struct GenerationConfig: Encodable {
        let responseMimeType: String
        let responseSchema: SchemaProperty
    }

    indirect enum SchemaProperty: Encodable {

        case string

        case array(
            items: SchemaProperty
        )

        case object(
            properties: [String: SchemaProperty],
            required: [String]
        )

        private enum CodingKeys: String, CodingKey {
            case type
            case items
            case properties
            case required
        }

        func encode(to encoder: Encoder) throws {

            var container = encoder.container(
                keyedBy: CodingKeys.self
            )

            switch self {

            case .string:
                try container.encode(
                    "STRING",
                    forKey: .type
                )

            case .array(let items):
                try container.encode(
                    "ARRAY",
                    forKey: .type
                )

                try container.encode(
                    items,
                    forKey: .items
                )

            case .object(let properties, let required):
                try container.encode(
                    "OBJECT",
                    forKey: .type
                )

                try container.encode(
                    properties,
                    forKey: .properties
                )

                try container.encode(
                    required,
                    forKey: .required
                )
            }
        }
    }
}

// MARK: - Response

private struct GeminiResponse: Decodable {

    let candidates: [Candidate]

    struct Candidate: Decodable {
        let content: Content
    }

    struct Content: Decodable {
        let parts: [Part]
    }

    struct Part: Decodable {
        let text: String
    }
}

// MARK: - Errors

private enum GeminiError: LocalizedError {
    case invalidResponse
    case missingContent
    case httpError(
        statusCode: Int,
        responseBody: String
    )

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Gemini returned an invalid HTTP response."

        case .missingContent:
            return "Gemini returned no generated content."

        case .httpError(let statusCode, let responseBody):
            return """
            Gemini request failed (\(statusCode)):
            \(responseBody)
            """
        }
    }
}
