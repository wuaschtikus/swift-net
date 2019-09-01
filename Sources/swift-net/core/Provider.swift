//
//  Provider.swift
//  kv-cli
//
//  Created by Martin Gruener on 06.08.19.
//

import Foundation
import Rainbow

public typealias RequestResult = Result<(HTTPURLResponse, Data), Error>

public struct Provider {
    private let session: URLSession
    private let verbose: Bool
    
    public init(verbose: Bool = false) {
        let urlSessionConfig = URLSessionConfiguration.default
        let urlSession = URLSession(configuration: urlSessionConfig)
        self.session = urlSession
        self.verbose = verbose
    }
}

extension Provider {
    public func request(target: TargetType, callback: @escaping (RequestResult) -> Void) {
        let request = createRequest(target: target)
        
        if verbose {
            print("""
                *** Request: \(request.httpMethod ?? "http method n/a") \(request.debugDescription)
                Headers: \(request.allHTTPHeaderFields ?? [:])
                Body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "")
                """.lightCyan)
        }
        
        let task = session.dataTask(with: request) { (result) in
            if self.verbose {
                switch result {
                case .success(let response, let data):
                    print("""
                        *** Response: \(response.url?.absoluteString ?? "") \(response.statusCode)
                        Headers: \(response.allHeaderFields)
                        Body: \(String(data: data, encoding: .utf8) ?? "n/a")
                        """.lightCyan)
                case .failure(let error):
                    print(error.localizedDescription.lightCyan)
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
