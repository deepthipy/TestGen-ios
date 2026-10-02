import SwiftUI
import UIKit

struct ContentView: View {

    @StateObject private var viewModel: TestGenerationViewModel
    @State private var copiedTestID: UUID?

    init(
        aiProvider: AIProvider = GeminiAIProvider(
            apiKey: AppConfiguration.geminiAPIKey
        )
    ) {
        _viewModel = StateObject(
            wrappedValue: TestGenerationViewModel(
                aiProvider: aiProvider
            )
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    sourceEditor
                    generateButton
                    resultSection
                }
                .padding()
            }
            .navigationTitle("TestGen")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("AI XCTest Generator")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Paste Swift code and generate unit tests.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Source Editor

    private var sourceEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Swift Source")
                .font(.headline)

            TextEditor(text: $viewModel.sourceCode)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 180)
                .padding(8)
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.secondary.opacity(0.3))
                }
        }
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button {
            viewModel.generateTests()
        } label: {
            HStack {
                Spacer()

                if case .loading = viewModel.state {
                    ProgressView()
                        .padding(.trailing, 4)

                    Text("Generating...")
                } else {
                    Image(systemName: "wand.and.stars")
                    Text("Generate Tests")
                }

                Spacer()
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isLoading)
    }

    // MARK: - Results

    @ViewBuilder
    private var resultSection: some View {
        switch viewModel.state {

        case .idle:
            EmptyView()

        case .loading:
            HStack(spacing: 8) {
                ProgressView()

                Text("Analysing your Swift code...")
                    .foregroundStyle(.secondary)
            }

        case .success(let suite):
            VStack(alignment: .leading, spacing: 20) {

                VStack(alignment: .leading, spacing: 4) {
                    Text("Generated XCTest")
                        .font(.headline)

                    Text(suite.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ForEach(suite.tests) { test in
                    testCard(test)
                }
            }

        case .failure(let message):
            Label(
                message,
                systemImage: "exclamationmark.triangle"
            )
            .foregroundStyle(.red)
        }
    }

    // MARK: - Test Card

    private func testCard(_ test: GeneratedTest) -> some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack(alignment: .firstTextBaseline) {
                Text(test.name)
                    .font(.headline)

                Spacer()

                copyButton(for: test)
            }

            Text(test.purpose)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(test.code)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .padding()
                .background(.secondary.opacity(0.08))
                .clipShape(
                    RoundedRectangle(cornerRadius: 10)
                )
        }
    }

    // MARK: - Copy Button

    private func copyButton(
        for test: GeneratedTest
    ) -> some View {
        Button {
            copy(test)
        } label: {
            if copiedTestID == test.id {
                Label(
                    "Copied",
                    systemImage: "checkmark"
                )
                .font(.subheadline)
            } else {
                Label(
                    "Copy",
                    systemImage: "doc.on.doc"
                )
                .font(.subheadline)
            }
        }
        .buttonStyle(.borderless)
    }

    // MARK: - Actions

    private func copy(_ test: GeneratedTest) {
        UIPasteboard.general.string = test.code
        copiedTestID = test.id

        Task {
            try? await Task.sleep(for: .seconds(2))

            if copiedTestID == test.id {
                copiedTestID = nil
            }
        }
    }

    // MARK: - Helpers

    private var isLoading: Bool {
        if case .loading = viewModel.state {
            return true
        }

        return false
    }
}

#Preview {
    ContentView(aiProvider: MockAIProvider())
}

