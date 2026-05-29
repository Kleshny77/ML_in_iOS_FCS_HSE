import Foundation

protocol MortgageCalculatorProtocol {
    func calculateMonthlyPayment(
        loanAmount: Double,
        annualRate: Double,
        termYears: Double
    ) -> Double
    
    func calculateResult(
        price: Double,
        settings: MortgageSettings
    ) -> MortgageResult
}

final class MortgageCalculator: MortgageCalculatorProtocol {
    
    static let shared = MortgageCalculator()
    
    private init() {}
    
    func calculateMonthlyPayment(
        loanAmount: Double,
        annualRate: Double,
        termYears: Double
    ) -> Double {
        guard loanAmount > 0 else { return 0 }
        
        let monthlyRate = (annualRate / 100) / 12
        let numberOfPayments = termYears * 12
        
        guard monthlyRate > 0 else {
            return loanAmount / numberOfPayments
        }
        
        let compoundFactor = pow(1 + monthlyRate, numberOfPayments)
        let numerator = monthlyRate * compoundFactor
        let denominator = compoundFactor - 1
        
        guard denominator > 0 else {
            return loanAmount / numberOfPayments
        }
        
        return loanAmount * (numerator / denominator)
    }
    
    func calculateResult(
        price: Double,
        settings: MortgageSettings
    ) -> MortgageResult {
        let downPaymentAmount = price * settings.downPaymentPercent / 100
        let loanAmount = price - downPaymentAmount
        
        let monthlyPayment = calculateMonthlyPayment(
            loanAmount: loanAmount,
            annualRate: settings.interestRate,
            termYears: settings.loanTermYears
        )
        
        return MortgageResult(
            price: price,
            settings: settings,
            monthlyPayment: monthlyPayment
        )
    }
}
