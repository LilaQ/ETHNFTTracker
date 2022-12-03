//
//  EtherscanAPI.swift
//  ETHNFTTracker
//
//  Created by Jan on 10.11.22.
//

import SwiftUI

class EtherscanAccoundBalanceResult: Codable {
    let status: String
    let message: String
    let result: String
}

class EtherscanGweiResult: Codable {
    class GweiResult: Codable {
        let LastBlock: String
        let SafeGasPrice: String
        let ProposeGasPrice: String
        let FastGasPrice: String
        let suggestBaseFee: String
        let gasUsedRatio: String
    }
    
    let status: String
    let message: String
    let result: GweiResult
}

class EtherscanEthPriceResult: Codable {
    class EthPriceResult: Codable {
        let ethbtc: String
        let ethbtc_timestamp: String
        let ethusd: String
        let ethusd_timestamp: String
    }
    let status: String
    let message: String
    let result: EthPriceResult
}

class EtherscanEthPriceHistoryResult: Codable {
    class EthPriceHistoryElementResult: Codable {
        let UTCDate: String
        let unixTimeStamp: String
        let value: String
    }
    let status: String
    let message: String
    let result: [EthPriceHistoryElementResult]
}



enum EtherscanAPIError: Error {
    case AccountBalanceError(Error)
    case GweiError(Error)
    case EthPriceError(Error)
    case EthPriceHistoryError(Error)
    case GenericRequestError(statusCode: Int)
}

class EtherscanAPI {
    
    private static func urlComponents() -> URLComponents {
        var urlComponents = URLComponents(string: "https://api.etherscan.io/api")!
        urlComponents.queryItems = [
            URLQueryItem(name: "apikey", value: Env.ETHERSCAN_API_KEY)
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
    
    static func loadAccountBalance(address: String, callback: @escaping (Result<EtherscanAccoundBalanceResult, EtherscanAPIError>)->()) {
        
        var urlComponents = urlComponents()
        urlComponents.queryItems?.append(contentsOf: [
            URLQueryItem(name: "module", value: "account"),
            URLQueryItem(name: "action", value: "balance"),
            URLQueryItem(name: "address", value: address),
            URLQueryItem(name: "tag", value: "latest")
        ])
        
        request(urlComponents: urlComponents) { (result: Result<EtherscanAccoundBalanceResult, Error>) in
            switch result {
            case .success(let success):
                callback(.success(success))
            case .failure(let failure):
                callback(.failure(.AccountBalanceError(failure)))
            }
        }
    }
    
    static func loadGwei(callback: @escaping (Result<EtherscanGweiResult, EtherscanAPIError>)->()) {
        var urlComponents = urlComponents()
        urlComponents.queryItems?.append(contentsOf: [
            URLQueryItem(name: "module", value: "gastracker"),
            URLQueryItem(name: "action", value: "gasoracle")
        ])
        
        request(urlComponents: urlComponents) { (result: Result<EtherscanGweiResult, Error>) in
            switch result {
            case .success(let success):
                callback(.success(success))
            case .failure(let failure):
                callback(.failure(.GweiError(failure)))
            }
        }
    }
    
    static func loadEthPrice(callback: @escaping (Result<EtherscanEthPriceResult, EtherscanAPIError>)->()) {
        var urlComponents = urlComponents()
        urlComponents.queryItems?.append(contentsOf: [
            URLQueryItem(name: "module", value: "stats"),
            URLQueryItem(name: "action", value: "ethprice")
        ])
        
        request(urlComponents: urlComponents) { (result: Result<EtherscanEthPriceResult, Error>) in
            switch result {
            case .success(let success):
                callback(.success(success))
            case .failure(let failure):
                callback(.failure(.EthPriceError(failure)))
            }
        }
    }
    
    static func loadEthPriceHistory(startDate: Date, endDate: Date, callback: @escaping (Result<EtherscanEthPriceHistoryResult, EtherscanAPIError>)->()) {
        var urlComponents = urlComponents()
        urlComponents.queryItems?.append(contentsOf: [
            URLQueryItem(name: "module", value: "stats"),
            URLQueryItem(name: "action", value: "ethdailyprice"),
            URLQueryItem(name: "startdate", value: startDate.dateOnly ),
            URLQueryItem(name: "enddate", value: endDate.dateOnly ),
            URLQueryItem(name: "sort", value: "asc")
        ])
        
        request(urlComponents: urlComponents) { (result: Result<EtherscanEthPriceHistoryResult, Error>) in
            switch result {
            case .success(let success):
                callback(.success(success))
            case .failure(let failure):
                callback(.failure(.EthPriceHistoryError(failure)))
            }
        }
    }
}

extension Date {
    var dateOnly: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
    
    var forAxis: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM."
        return formatter.string(from: self)
    }
    
    var minus30days: Date {
        return Calendar.current.date(byAdding: .day, value: -30, to: self) ?? self
    }
    
    func minusDays(_ d: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: -d, to: self) ?? self
    }
}
