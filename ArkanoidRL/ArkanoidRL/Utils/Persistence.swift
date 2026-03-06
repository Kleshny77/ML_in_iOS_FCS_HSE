import Foundation

final class NetworkPersistence {
    private static let directoryName = "ArkanoidRL"
    private static let fileName = "neural-network-state.json"

    private static func applicationSupportDirectory() throws -> URL {
        let baseURL = try FileManager.default
            .url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
        let directoryURL = baseURL.appendingPathComponent(directoryName, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        return directoryURL
    }

    static func defaultModelURL() throws -> URL {
        try applicationSupportDirectory().appendingPathComponent(fileName)
    }

    static func save(weights: [[Double]], to url: URL) throws {
        let data = try JSONEncoder().encode(weights)
        try data.write(to: url, options: .atomic)
    }

    static func load(from url: URL) throws -> [[Double]] {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([[Double]].self, from: data)
    }

    static func saveModelState(_ state: NeuralNetworkState) throws {
        try saveModelState(state, to: defaultModelURL())
    }

    static func saveModelState(_ state: NeuralNetworkState, to url: URL) throws {
        let data = try JSONEncoder().encode(state)
        try data.write(to: url, options: .atomic)
    }

    static func loadModelState() throws -> NeuralNetworkState {
        let data = try Data(contentsOf: defaultModelURL())
        return try JSONDecoder().decode(NeuralNetworkState.self, from: data)
    }

    static func loadModelStateIfAvailable() -> NeuralNetworkState? {
        do {
            let url = try defaultModelURL()
            guard FileManager.default.fileExists(atPath: url.path) else {
                return nil
            }
            return try loadModelState()
        } catch {
            return nil
        }
    }

    static func deleteSavedModel() throws {
        let url = try defaultModelURL()
        guard FileManager.default.fileExists(atPath: url.path) else {
            return
        }
        try FileManager.default.removeItem(at: url)
    }
}

