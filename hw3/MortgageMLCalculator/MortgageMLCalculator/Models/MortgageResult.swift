import Foundation

struct MortgageSettings {
    var downPaymentPercent: Double
    var loanTermYears: Double
    var interestRate: Double
    
    static let `default` = MortgageSettings(
        downPaymentPercent: 20,
        loanTermYears: 20,
        interestRate: 7.5
    )
    
    var monthlyInterestRate: Double {
        (interestRate / 100) / 12
    }
    
    var totalMonths: Double {
        loanTermYears * 12
    }
}

struct MortgageResult {
    let predictedPrice: Double
    let downPaymentAmount: Double
    let loanAmount: Double
    let monthlyPayment: Double
    let totalPayment: Double
    let overpayment: Double
    let overpaymentPercent: Double
    let settings: MortgageSettings
    
    init(price: Double, settings: MortgageSettings, monthlyPayment: Double) {
        self.predictedPrice = price
        self.settings = settings
        
        self.downPaymentAmount = price * settings.downPaymentPercent / 100
        self.loanAmount = price - downPaymentAmount
        self.monthlyPayment = monthlyPayment
        self.totalPayment = monthlyPayment * settings.totalMonths
        self.overpayment = totalPayment - loanAmount
        self.overpaymentPercent = loanAmount > 0 ? (overpayment / loanAmount) * 100 : 0
    }
}

extension Double {
    var asCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₽"
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: self)) ?? "\(Int(self)) ₽"
    }
    
    var asPercent: String {
        String(format: "%.1f%%", self)
    }
}
