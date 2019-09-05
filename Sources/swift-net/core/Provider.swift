//
//  Provider.swift
//  kv-cli
//
//  Created by Martin Gruener on 06.08.19.
//

import Foundation
import Rainbow
import SwiftyBeaver

let log = SwiftyBeaver.self
let console = ConsoleDestination()

public typealias RequestResult = Result<(HTTPURLResponse, Data), Error>

var df: DateFormatter {
    get {
        let df = DateFormatter()
        df.dateFormat = "y-MM-dd H:m:ss.SSSS"
        return df
    }
}

public struct Provider {
    private let session: URLSession
    private let verbose: Bool
    
    public init(verbose: Bool = false) {
        let urlSessionConfig = URLSessionConfiguration.default
        let urlSession = URLSession(configuration: urlSessionConfig)
        self.session = urlSession
        self.verbose = verbose
        
        log.addDestination(console)
    }
}

extension Provider {
    public func request(target: TargetType, callback: @escaping (RequestResult) -> Void) {
        let request = createRequest(target: target)
        
        let task = session.dataTask(with: request) { (result) in
            if self.verbose {
                switch result {
                case .success(let response, let data):
                    let timestamp = Date()
                    
                    log.verbose("\(df.string(from: timestamp)) \(request.httpMethod ?? "http method n/a") \(request.debugDescription) \(response.statusCode)".lightCyan)
                    
                    if let headers = request.allHTTPHeaderFields {
                        headers.forEach { (key, value) in
                            log.verbose("\(df.string(from: timestamp)) \(key): \(value)".lightCyan)
                        }
                    }
                    
                    log.verbose("\(df.string(from: timestamp)) Body: \(String(data: data, encoding: .utf8) ?? "")".lightCyan)
                    
                case .failure(let error):
                    log.error("\(error)")
                }
            }
            callback(result)
        }
        
        task.resume()
    }
    
    private func createRequest(target: TargetType) -> URLRequest {
        do {
            let s = target.baseURL.absoluteString + target.path
            let url = URL(string: s)
            var r = URLRequest(url: url!)
            r.httpMethod = target.method.rawValue
            r.allHTTPHeaderFields = target.headers
            
            switch target.task {
            case .requestPlain:()
            case .requestData(let data):
                r.httpBody = data
            case .requestParameters(let parameters, let encoding):
                r = try encoding.encode(r, with: parameters)
            case .uploadMultipart(let imageData):
                let boundary = "Boundary-\(UUID().uuidString)"
                r.allHTTPHeaderFields?["Content-Type"] = "multipart/form-data; boundary=\(boundary)"
                r.httpBody = createBody(parameters: [:],
                                        boundary: boundary,
                                        data: imageData,
                                        mimeType: "image/jpg",
                                        filename: "file")
            case .requestCompositeData(let bodyData, let urlParameters):
                r = try URLEncoding.queryString.encode(r, with: urlParameters)
                r.httpBody = bodyData
                
            }
            
            return r
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    private func createBody(parameters: [String: String],
                            boundary: String,
                            data: Data,
                            mimeType: String,
                            filename: String) -> Data {
        let body = NSMutableData()
        
        let boundaryPrefix = "--\(boundary)\r\n"
        
        for (key, value) in parameters {
            body.appendString(boundaryPrefix)
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.appendString("\(value)\r\n")
        }
        
        body.appendString(boundaryPrefix)
        body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mimeType)\r\n\r\n")
        body.append(data)
        body.appendString("\r\n")
        body.appendString("--".appending(boundary.appending("--")))
        
        return body as Data
    }
}

extension NSMutableData {
    func appendString(_ string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false)
        append(data!)
    }
}

extension URLSession {
    func dataTask(with request: URLRequest, result: @escaping (RequestResult) -> Void) -> URLSessionDataTask {
        return dataTask(with: request) { (data, response, error) in
            if let error = error {
                result(.failure(error))
                return
            }
            guard let response = response as? HTTPURLResponse, let data = data else {
                let error = NSError(domain: "error", code: 0, userInfo: nil)
                result(.failure(error))
                return
            }
            result(.success((response, data)))
        }
    }
}
