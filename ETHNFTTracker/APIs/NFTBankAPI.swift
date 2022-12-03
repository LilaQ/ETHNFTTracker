//
//  NFTBankAPI.swift
//  ETHNFTTracker
//
//  Created by Jan on 23.11.22.
//

import SwiftUI

enum NFTBankAPIError: Error {
    case GenericRequestError(statusCode: Int)
}

struct NFTBankAPIFloorpriceResult: Codable {
    var response: Int
    var data: [NFTBankAPIFloorpriceResultData]
}

struct NFTBankAPIFloorpriceResultData: Codable {
    var _id: String
    var asset_contract: String
    var asset_info: NFTBankAPIAssetInfo
    var chain_info: String
    var dapp_info: NFTBankAPIDappInfo
    var estimated_at: String
    var floor_price: [NFTBankFloorPrice]
}

struct NFTBankAPIAssetInfo: Codable {
    var contract_address: String
    var name: String
    var symbol: String
}

struct NFTBankAPIDappInfo: Codable {
    var id: String
    var image_url: String
    var name: String
}

struct NFTBankFloorPrice: Codable {
    var currency_symbol: String
    var floor_price: Double
}

class NFTBankAPI {
    
    private static func urlComponents() -> URLComponents {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "NFTBANK_API_KEY") as? String else {
            fatalError("FATAL_ERROR - No API key for NFTBank provided in Info.plist")
        }
        var urlComponents = URLComponents(string: apiKey)!
        urlComponents.queryItems = [
            URLQueryItem(name: "x-api-key", value: apiKey)
        ]
        return urlComponents
    }
    
    private static func request<T: Decodable>(urlComponents: URLComponents, callback: @escaping (Result<T, Error>)->()) {
        guard let url = urlComponents.url else { return }
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print(String(decoding: data!, as: UTF8.self))
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
    
    static func loadNFTFloorprice(contract: String, callback: @escaping (Result<NFTBankAPIFloorpriceResult, NFTBankAPIError>)->()) {
        
        var urlComponents = urlComponents()
        urlComponents.path += "floor_price/"
        urlComponents.path += contract
        
        urlComponents.queryItems?.append(contentsOf: [
            URLQueryItem(name: "chain_id", value: "ETHEREUM")
            
        ])
        
        request(urlComponents: urlComponents) { (result: Result<NFTBankAPIFloorpriceResult, Error>) in
            switch result {
            case .success(let success):
                callback(.success(success))
            case .failure(_):
                callback(.failure(.GenericRequestError(statusCode: 0)))
            }
        }
    }
}
