//
//  EtherscanAPI.swift
//  ETHNFTTracker
//
//  Created by Jan on 10.11.22.
//

import SwiftUI

enum BlockdeamonAPIError: Error {
    case NFTListError(Error)
    case GenericRequestError(statusCode: Int)
}

class BlockdaemonNFTListResult: Codable {
    class BlockdaemonNFTResult: Codable {
        let id: String
        let token_id: String
        let image_url: String
        let name: String
        let contract_address: String
    }
    var data: [BlockdaemonNFTResult]
}

class BlockdaemonAPI {
    
    private static func urlComponents() -> URLComponents {
        var urlComponents = URLComponents(string: "https://svc.blockdaemon.com/nft/v1/ethereum/mainnet")!
        urlComponents.queryItems = []
        return urlComponents
    }
    
    private static func request<T: Decodable>(urlComponents: URLComponents, callback: @escaping (Result<T, Error>)->()) {
        guard let url = urlComponents.url else { return }
        var request = URLRequest(url: url)
        request.setValue(Env.BLOCKDAEMON_API_KEY, forHTTPHeaderField: "X-API-Key")
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
    
    static func loadAccountNFTs(address: String, callback: @escaping (Result<BlockdaemonNFTListResult, BlockdeamonAPIError>)->()) {
        
        var urlComponents = urlComponents()
        urlComponents.path += "/assets"
        urlComponents.queryItems?.append(contentsOf: [
            URLQueryItem(name: "wallet_address", value: address)
        ])
        
        request(urlComponents: urlComponents) { (result: Result<BlockdaemonNFTListResult, Error>) in
            switch result {
            case .success(let success):
                callback(.success(success))
            case .failure(let failure):
                callback(.failure(.NFTListError(failure)))
            }
        }
    }
}
