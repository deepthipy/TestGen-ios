import Foundation

enum AppConfiguration {

    static var geminiAPIKey: String {
        guard let key = Bundle.main.object(
            forInfoDictionaryKey: "GEMINI_API_KEY"
        ) as? String,
        !key.isEmpty,
        !key.contains("$(") else {
            fatalError("GEMINI_API_KEY is missing from the app configuration.")
        }

        return key
    }
}
