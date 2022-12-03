//
//  EtherscanAPI.swift
//  ETHNFTTracker
//
//  Created by Jan on 10.11.22.
//

import SwiftUI

enum CryptoCompareAPIError: Error {
    case EthPriceHistoryError(Error)
    case GenericRequestError(statusCode: Int)
}

class CryptoCompareEthPriceHistoryResult: Codable {
    class CryptoCompareEthPriceHistoryTypeResult: Codable {
        class CryptoCompareEthPriceHistoryTypeDataResult: Codable {
            let high: Double
            let low: Double
            let open: Double
            let close: Double
        }
        var Data: [CryptoCompareEthPriceHistoryTypeDataResult]
    }
    let Data: CryptoCompareEthPriceHistoryTypeResult
}

class CryptoCompareAPI {
    
    private static func urlComponents() -> URLComponents {
        var urlComponents = URLComponents(string: "https://min-api.cryptocompare.com/data/v2")!
        urlComponents.queryItems = [
            URLQueryItem(name: "api_key", value: Env.CRYPTOCOMPARE_API_KEY)
        ]
        return urlComponents
    }
    
    private static func request<T: Decodable>(urlComponents: URLComponents, callback: @escaping (Result<T, Error>)->()) {
        guard let url = urlComponents.url else { return }
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                callback(.failure(error))
            } else if let response = response as? HTTPURLResponse, !(200...299).contains(response.statusCode) {
                print(String(decoding: data!, as: UTF8.self))
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
    
    enum Timing {
        case DAILY
        case HOURLY
    }
    
    static func loadEthPriceHistory(timing: Timing = .DAILY, callback: @escaping (Result<CryptoCompareEthPriceHistoryResult, CryptoCompareAPIError>)->()) {
        
        var urlComponents = urlComponents()
        
        switch timing {
        case .DAILY:
            urlComponents.path += "/histoday"
        case .HOURLY:
            urlComponents.path += "/histohour"
        }
        
        urlComponents.queryItems?.append(contentsOf: [
            URLQueryItem(name: "fsym", value: "ETH"),
            URLQueryItem(name: "tsym", value: "USD"),
            URLQueryItem(name: "limit", value: "30")
        ])
        
        request(urlComponents: urlComponents) { (result: Result<CryptoCompareEthPriceHistoryResult, Error>) in
            switch result {
            case .success(let success):
                callback(.success(success))
            case .failure(let failure):
                callback(.failure(.EthPriceHistoryError(failure)))
            }
        }
    }
}
