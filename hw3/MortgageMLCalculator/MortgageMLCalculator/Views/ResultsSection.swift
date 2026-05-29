import SwiftUI

struct ResultsSection: View {
    
    @ObservedObject var viewModel: MortgageViewModel
    
    var body: some View {
        Section {
            Group {
                if viewModel.isCalculating {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(message: error)
                } else if let result = viewModel.result {
                    resultView(result: result)
                } else {
                    placeholderView
                }
            }
        } header: {
            Text("Результаты расчёта")
        }
    }
    
    private var loadingView: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text("Рассчитываем...")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private func errorView(message: String) -> some View {
        Label {
            Text(message)
                .foregroundColor(.orange)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
        }
        .padding(.vertical, 4)
    }
    
    private var placeholderView: some View {
        Text("Введите параметры для расчёта")
            .foregroundColor(.secondary)
            .padding(.vertical, 8)
    }
    
    private func resultView(result: MortgageResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            priceView(result: result)
            
            Divider()
            
            mortgageDetailsView(result: result)
        }
        .padding(.vertical, 8)
    }
    
    private func priceView(result: MortgageResult) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Прогнозируемая стоимость")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(result.predictedPrice.asCurrency)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
        }
    }
    
    private func mortgageDetailsView(result: MortgageResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ипотечный расчёт")
                .font(.caption)
                .foregroundColor(.secondary)
            
            DetailRow(
                title: "Первоначальный взнос:",
                value: "\(Int(result.settings.downPaymentPercent))%",
                valueColor: .primary
            )
            
            DetailRow(
                title: "Сумма кредита:",
                value: result.loanAmount.asCurrency,
                valueColor: .primary
            )
            
            DetailRow(
                title: "Ежемесячный платёж:",
                value: result.monthlyPayment.asCurrency,
                valueColor: .green,
                isHighlighted: true
            )
            
            DetailRow(
                title: "Переплата за \(Int(result.settings.loanTermYears)) лет:",
                value: result.overpayment.asCurrency,
                valueColor: .red
            )
            
            DetailRow(
                title: "Переплата:",
                value: result.overpaymentPercent.asPercent,
                valueColor: .orange,
                font: .caption
            )
        }
    }
}

private struct DetailRow: View {
    let title: String
    let value: String
    var valueColor: Color = .primary
    var isHighlighted: Bool = false
    var font: Font = .body
    
    var body: some View {
        HStack {
            Text(title)
                .font(font)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(isHighlighted ? .headline : font)
                .fontWeight(isHighlighted ? .bold : .medium)
                .foregroundColor(valueColor)
        }
    }
}

#Preview {
    List {
        ResultsSection(viewModel: {
            let vm = MortgageViewModel()
            vm.result = MortgageResult(
                price: 7_500_000,
                settings: .default,
                monthlyPayment: 52_340
            )
            return vm
        }())
    }
}
