import SwiftUI

struct ContentView: View {
    
    @StateObject private var viewModel = MortgageViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                PropertyInputSection(viewModel: viewModel)
                
                MortgageSettingsSection(viewModel: viewModel)
                
                ResultsSection(viewModel: viewModel)
            }
            .navigationTitle("Ипотечный калькулятор")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Готово") {
                        hideKeyboard()
                    }
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

#Preview {
    ContentView()
}
