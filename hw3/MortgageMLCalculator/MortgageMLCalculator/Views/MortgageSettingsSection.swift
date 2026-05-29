import SwiftUI

struct MortgageSettingsSection: View {
    
    @ObservedObject var viewModel: MortgageViewModel
    
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Первоначальный взнос")
                    Spacer()
                    Text("\(Int(viewModel.mortgageSettings.downPaymentPercent))%")
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                Slider(
                    value: $viewModel.mortgageSettings.downPaymentPercent,
                    in: 10...50,
                    step: 5
                )
                .tint(.blue)
            }
            .padding(.vertical, 4)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Срок кредита")
                    Spacer()
                    Text("\(Int(viewModel.mortgageSettings.loanTermYears)) лет")
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                Slider(
                    value: $viewModel.mortgageSettings.loanTermYears,
                    in: 5...30,
                    step: 1
                )
                .tint(.blue)
            }
            .padding(.vertical, 4)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Процентная ставка")
                    Spacer()
                    Text(String(format: "%.1f%%", viewModel.mortgageSettings.interestRate))
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                Slider(
                    value: $viewModel.mortgageSettings.interestRate,
                    in: 3...20,
                    step: 0.1
                )
                .tint(.blue)
            }
            .padding(.vertical, 4)
            
        } header: {
            Text("Условия ипотеки")
        }
    }
}

#Preview {
    List {
        MortgageSettingsSection(viewModel: MortgageViewModel())
    }
}
