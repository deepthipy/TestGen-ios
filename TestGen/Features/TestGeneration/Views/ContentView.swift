import SwiftUI

struct ContentView: View {

    @StateObject private var viewModel: TestGenerationViewModel

    init(aiProvider: AIProvider = MockAIProvider()) {
        _viewModel = StateObject(
            wrappedValue: TestGenerationViewModel(aiProvider: aiProvider)
        )
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {

                header

                sourceEditor

                generateButton

                resultSection

                Spacer()
            }
            .padding()
            .navigationTitle("TestGen")
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

    // MARK: - Generate

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

    // MARK: - Result

    @ViewBuilder
    private var resultSection: some View {
        switch viewModel.state {

        case .idle:
            EmptyView()

        case .loading:
            Text("Analysing your Swift code...")
                .foregroundStyle(.secondary)

        case .success(let suite):
            VStack(alignment: .leading, spacing: 16) {

                VStack(alignment: .leading, spacing: 4) {
                    Text("Generated XCTest")
                        .font(.headline)

                    Text(suite.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ForEach(suite.tests) { test in
                    VStack(alignment: .leading, spacing: 8) {

                        Text(test.name)
                            .font(.headline)

                        Text(test.purpose)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal) {
                            Text(test.code)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(
                                    maxWidth: .infinity,
                                    alignment: .leading
                                )
                                .padding()
                        }
                        .background(.secondary.opacity(0.08))
                        .clipShape(
                            RoundedRectangle(cornerRadius: 10)
                        )
                    }
                }
            }

        case .failure(let message):
            Label(message, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.red)
        }
    }

    private var isLoading: Bool {
        if case .loading = viewModel.state {
            return true
        }

        return false
    }
}

#Preview {
    ContentView()
}
