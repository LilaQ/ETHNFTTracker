//
//  EnjObject.swift
//  ETHNFTTracker
//
//  Created by Jan on 10.11.22.
//

import SwiftUI

class Env {
    
    static let shared = Env()
    static let ETHERSCAN_API_KEY = "65DZ4DXY6HFSUBBH6IZM2X3K3AK355R1J2"
    static let BLOCKDAEMON_API_KEY = "sLM84fH17eeywaAoJwBSNOwcx6roydRrIM2EcptlJcfIGOmJ"
    static let CRYPTOCOMPARE_API_KEY = "44f524e9548cf092ac1a306647ab0951fde39398a8a34409f12eb1163cfe2a03"
    static let ALCHEMY_API_KEY = "LbjM-xXnVtsdmmDuM8a5FghTuO8lzAje"
    static let ALCHEMY_BASE_URI = "https://eth-mainnet.g.alchemy.com/nft/v2/"
    static let BLOCKDAEMON_BASE_URI = "https://svc.blockdaemon.com/nft/v1/ethereum/mainnet/"
    static let BLOCKDAEMON_IMAGE_URI = BLOCKDAEMON_BASE_URI + "/media/"
    
    static let NFTBANK_BASE_URI = "https://api.nftbank.ai/estimates-v2/"
    
    var EthPriceHistoryMinutes = Fifo(limit: 24)
    var EthPriceHistoryDaily = Fifo(limit: 30)
    var NFTs: [String:AlchemyNFTsResult] = [:]
    var floorPrices: [String: Double] = [:]
    var collectionValue: Double = 0.0
    var updateFloorPrices: (()->())? = nil
}

extension Array: RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Element].self, from: data)
        else {
            return nil
        }
        self = result
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}

struct Fifo {
    var elements: [Double] = []
    private var limit: Int = 10
    
    init(limit: Int) {
        self.limit = limit
    }
    
    mutating func push(_ value: Double) {
        elements.append(value)
        while self.elements.count > limit {
            _ = self.pop()
        }
    }
    
    mutating func pop() -> Double? {
        guard !elements.isEmpty else {
            return nil
        }
        return elements.removeFirst()
    }
}

extension [Double] {
    var chartPrepared: [Double] {
        self.map({ ($0 - (self.min() ?? 0.0).rounded(FloatingPointRoundingRule.down)) / ((self.max() ?? 1.0).rounded(FloatingPointRoundingRule.up) - (self.min() ?? 0.0).rounded(FloatingPointRoundingRule.down)) })
    }
}
