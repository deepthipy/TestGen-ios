
import Foundation
import Combine

@MainActor
final class TestGenerationViewModel: ObservableObject {

    @Published var sourceCode = ""
    @Published private(set) var state: GenerationState = .idle

    private let aiProvider: AIProvider
    private var generationTask: Task<Void, Never>?

    init(aiProvider: AIProvider) {
        self.aiProvider = aiProvider
    }

    func generateTests() {
        guard !sourceCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            state = .failure("Enter Swift source code before generating tests.")
            return
        }

        generationTask?.cancel()

        generationTask = Task {
            state = .loading

            do {
                let generatedCode = try await aiProvider.generateTests(
                    for: sourceCode
                )

                try Task.checkCancellation()

                state = .success(generatedCode)

            } catch is CancellationError {
                return

            } catch {
                state = .failure(error.localizedDescription)
            }
        }
    }

    func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
        state = .idle
    }
}
