import Foundation

struct Experience: Codable {
    let state: [Double]
    let action: Double
    let reward: Double
    let nextState: [Double]
}
