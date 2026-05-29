import Foundation

struct FCSPriceResponse: Codable, Sendable {
    let code: Int?
    let msg: String?
    let response: [FCSPriceItem]?
}

struct FCSPriceItem: Codable, Identifiable, Sendable {
    let id: String?
    let s: String?
    let c: String?
    let t: String?
    let ch: String?
    let cp: String?
    let tm: String?
    let o: String?
    let h: String?
    let l: String?

    var symbol: String { s ?? "" }
    var price: String? { c }
    var parsedPrice: Double? {
        guard let str = c?.replacingOccurrences(of: ",", with: "") else { return nil }
        return Double(str)
    }
}

struct FCSHistoryResponse: Codable, Sendable {
    let code: Int?
    let msg: String?
    let response: [String: FCSHistoryCandle]?

    var candles: [FCSHistoryCandle] {
        guard let response = response else { return [] }
        return response.values.sorted {
            let a = $0.tm ?? $0.t ?? ""
            let b = $1.tm ?? $1.t ?? ""
            return a < b
        }
    }
}

struct FCSHistoryCandle: Codable, Identifiable, Sendable {
    let id: String?
    let o: String?
    let h: String?
    let l: String?
    let c: String?
    let t: String?
    let tm: String?
    let v: String?

    enum CodingKeys: String, CodingKey {
        case id, o, h, l, c, t, tm, v
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        o = try container.decodeIfPresent(String.self, forKey: .o)
        h = try container.decodeIfPresent(String.self, forKey: .h)
        l = try container.decodeIfPresent(String.self, forKey: .l)
        c = try container.decodeIfPresent(String.self, forKey: .c)
        tm = try container.decodeIfPresent(String.self, forKey: .tm)
        v = try container.decodeIfPresent(String.self, forKey: .v)

        if let stringT = try? container.decodeIfPresent(String.self, forKey: .t) {
            t = stringT
        } else if let intT = try? container.decodeIfPresent(Int.self, forKey: .t) {
            t = String(intT)
        } else {
            t = nil
        }
    }

    var parsedOpen: Double? {
        guard let str = o?.replacingOccurrences(of: ",", with: "") else { return nil }
        return Double(str)
    }
    var parsedHigh: Double? {
        guard let str = h?.replacingOccurrences(of: ",", with: "") else { return nil }
        return Double(str)
    }
    var parsedLow: Double? {
        guard let str = l?.replacingOccurrences(of: ",", with: "") else { return nil }
        return Double(str)
    }
    var parsedClose: Double? {
        guard let str = c?.replacingOccurrences(of: ",", with: "") else { return nil }
        return Double(str)
    }
    var parsedVolume: Double? {
        guard let str = v?.replacingOccurrences(of: ",", with: "") else { return nil }
        return Double(str)
    }
}

struct FCSNewsResponse: Codable, Sendable {
    let code: Int?
    let msg: String?
    let response: [FCSNewsItem]?
}

struct FCSNewsItem: Codable, Identifiable, Sendable {
    let id: String?
    let title: String?
    let description: String?
    let date: String?
    let source: String?
}

struct FCSCurrenciesResponse: Codable, Sendable {
    let code: Int?
    let msg: String?
    let response: [FCSCurrency]?
}

struct FCSCurrency: Codable, Identifiable, Sendable {
    let id: String?
    let name: String?
    let symbol: String?

    var displayName: String { name ?? symbol ?? id ?? "" }
}

struct FCSIndicatorsResponse: Codable, Sendable {
    let code: Int?
    let msg: String?
    let response: [FCSIndicator]?
}

struct FCSIndicator: Codable, Identifiable, Sendable {
    let id: String?
    let s: String?
    let n: String?
    let v: String?

    var symbol: String { s ?? "" }
    var name: String { n ?? "" }
    var value: String? { v }
}

struct V2Candle: Codable, Identifiable, Sendable {
    var id: String { "\(base_currency ?? "")_\(quote_currency ?? "")_\(start_time ?? "")" }
    let base_currency: String?
    let quote_currency: String?
    let start_time: String?
    let open_time: String?
    let close_time: String?
    let open_bid: String?
    let open_ask: String?
    let open_midpoint: String?
    let close_bid: String?
    let close_ask: String?
    let close_midpoint: String?
    let high_bid: String?
    let high_ask: String?
    let high_midpoint: String?
    let low_bid: String?
    let low_ask: String?
    let low_midpoint: String?
    let average_bid: String?
    let average_ask: String?
    let average_midpoint: String?

    var parsedOpen: Double? { open_midpoint.flatMap(Double.init) ?? open_bid.flatMap(Double.init) }
    var parsedHigh: Double? { high_midpoint.flatMap(Double.init) ?? high_bid.flatMap(Double.init) }
    var parsedLow: Double? { low_midpoint.flatMap(Double.init) ?? low_bid.flatMap(Double.init) }
    var parsedClose: Double? { close_midpoint.flatMap(Double.init) ?? close_bid.flatMap(Double.init) }
}
