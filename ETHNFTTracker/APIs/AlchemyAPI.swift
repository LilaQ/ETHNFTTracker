//
//  EtherscanAPI.swift
//  ETHNFTTracker
//
//  Created by Jan on 10.11.22.
//

import SwiftUI

enum AlchemyAPIError: Error {
    case GetNFTsError(Error)
    case GenericRequestError(statusCode: Int)
}

class AlchemyTokenUriResult: Codable {
    let raw: String
    let gateway: String
}

class AlchemyMediaResult: Codable {
    let raw: String
    let gateway: String
    let thumbnail: String?
    let format: String?
}

class AlchemyAttributesResult: Codable, Hashable {
    var identifier: String {
        return UUID().uuidString
    }
    
    static func == (lhs: AlchemyAttributesResult, rhs: AlchemyAttributesResult) -> Bool {
        lhs.identifier == rhs.identifier
    }
    
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(identifier)
    }
    
    let value: String
    let trait_type: String?
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        trait_type = try container.decodeIfPresent(String.self, forKey: .trait_type)
        do {
            value = try String(container.decode(Int.self, forKey: .value))
        } catch DecodingError.typeMismatch {
            value = try container.decode(String.self, forKey: .value)
        }
    }
}

class AlchemyMetadataResult: Codable {
    let image: String?
    let name: String?
    let description: String?
    let attributes: [AlchemyAttributesResult]?
}

class AlchemyIdResult: Codable, Hashable {
    static func == (lhs: AlchemyIdResult, rhs: AlchemyIdResult) -> Bool {
        lhs.tokenId == rhs.tokenId
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(tokenId)
    }
    
    let tokenId: String
}

class AlchemyOpenSeaResult: Codable {
    let floorPrice: Double?
    let collectionName: String?
    let imageUrl: String?
    let description: String?
}

class AlchemyContractMetadataResult: Codable {
    let name: String?
    let symbol: String?
    let totalSupply: String?
    let openSea: AlchemyOpenSeaResult
}

class AlchemySpamInfoResult: Codable {
    let isSpam: String
    let classifications: [String]
}

struct AlchemyFloorPriceResult: Codable {
    let openSea: AlchemyFloorPriceMarketplace
    let looksRare: AlchemyFloorPriceMarketplace
}

struct AlchemyFloorPriceMarketplace: Codable {
    let floorPrice: Double?
    let priceCurrency: String?
    let retrievedAt: String?
    let collectionUrl: String?
}

struct AlchemyContract: Codable {
    let address: String
}

class AlchemyNFTsResult: Codable, Identifiable {
    class AlchemyNFTsOwnedNftsResult: Codable, Equatable {
        static func == (lhs: AlchemyNFTsResult.AlchemyNFTsOwnedNftsResult, rhs: AlchemyNFTsResult.AlchemyNFTsOwnedNftsResult) -> Bool {
            lhs.id == rhs.id
        }
        
        let id: AlchemyIdResult
        let contract: AlchemyContract
        let balance: String
        let title: String
        let description: String
        let tokenUri: AlchemyTokenUriResult
        let media: [AlchemyMediaResult]
        let metadata: AlchemyMetadataResult
        let contractMetadata: AlchemyContractMetadataResult?
        let spamInfo: AlchemySpamInfoResult?
    }
    let ownedNfts: [AlchemyNFTsOwnedNftsResult]
    let totalCount: Int
}

class AlchemyAPI {
    
    private static func urlComponents() -> URLComponents {
        var urlComponents = URLComponents(string: Env.ALCHEMY_BASE_URI)!
        urlComponents.path += Env.ALCHEMY_API_KEY
        urlComponents.queryItems = []
        return urlComponents
    }
    
    private static func request<T: Decodable>(urlComponents: URLComponents, callback: @escaping (Result<T, Error>)->()) {
        guard let url = urlComponents.url else { return }
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                if let data = data {
                    print(String(decoding: data, as: UTF8.self))
                }
                callback(.failure(error))
            } else if let response = response as? HTTPURLResponse, !(200...299).contains(response.statusCode) {
                callback(.failure(NSError()))
                return
            } else {
                do {
                    guard let d = data else { return }
                    let result = try JSONDecoder().decode(T.self, from: d)
                    callback(.success(result))
                }
                catch {
                    print(error)
                    print(String(decoding: data!, as: UTF8.self))
                }
            }
        }.resume()
    }
    
    private static func request<T: Decodable>(urlComponents: URLComponents, callback: @escaping (Result<T, Error>)->()) async {
        guard let url = urlComponents.url else { return }
        let request = URLRequest(url: url)
        let (data, response) = try! await URLSession.shared.data(for: request)
        if let response = response as? HTTPURLResponse, !(200...299).contains(response.statusCode) {
            callback(.failure(NSError()))
            return
        } else {
            do {
                let result = try JSONDecoder().decode(T.self, from: data)
                callback(.success(result))
            }
            catch {
                print(error)
                print(String(decoding: data, as: UTF8.self))
            }
        }
    }
    
    static func loadNfts(address: String, callback: @escaping (Result<AlchemyNFTsResult, AlchemyAPIError>)->()) async {
        
        var urlComponents = urlComponents()
        urlComponents.path += "/getNFTs"
        
        urlComponents.queryItems?.append(contentsOf: [
            URLQueryItem(name: "owner", value: address)
        ])
        
        await request(urlComponents: urlComponents) { (result: Result<AlchemyNFTsResult, Error>) in
            switch result {
            case .success(let success):
                callback(.success(success))
            case .failure(let failure):
                callback(.failure(.GetNFTsError(failure)))
            }
        }
    }
    
    static func loadFloorPrice(contractAddress: String, callback: @escaping (Result<AlchemyFloorPriceResult, AlchemyAPIError>)->()) async {
        
        var urlComponents = urlComponents()
        urlComponents.path += "/getFloorPrice"
        
        urlComponents.queryItems?.append(contentsOf: [
            URLQueryItem(name: "contractAddress", value: contractAddress)
        ])
        
        await request(urlComponents: urlComponents) { (result: Result<AlchemyFloorPriceResult, Error>) in
            switch result {
            case .success(let success):
                callback(.success(success))
            case .failure(let failure):
                callback(.failure(.GetNFTsError(failure)))
            }
        }
    }
}
