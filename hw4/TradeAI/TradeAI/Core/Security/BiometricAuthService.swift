import Foundation
import LocalAuthentication

enum BiometricAuthResult {
    case success
    case failure(Error)
    case notAvailable
}

actor BiometricAuthService {

    private let context = LAContext()

    func canAuthenticate() -> Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func authenticate(reason: String) async -> BiometricAuthResult {
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .notAvailable
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success ? .success : .failure(LAError(.userCancel))
        } catch {
            return .failure(error)
        }
    }

    func authenticateForHighValueOperation() async -> BiometricAuthResult {
        await authenticate(reason: "Подтвердите операцию с помощью биометрии для обеспечения безопасности.")
    }
}
