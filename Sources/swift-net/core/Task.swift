//
//  Task.swift
//  Rainbow
//
//  Created by Martin Grüner on 25.08.19.
//

import Foundation

/// Represents an HTTP task.
public enum Task {
    
    /// A request with no additional data.
    case requestPlain
    
    /// A requests body set with data.
    case requestData(Data)
    
    /// A requests body set with encoded parameters.
    case requestParameters(parameters: [String: Any], encoding: ParameterEncoding)
    
    // A requests body set with data, combined with url parameters.
    case requestCompositeData(bodyData: Data, urlParameters: [String: Any])
    
    /// A requests body set with encoded parameters combined with url parameters.
    // case requestCompositeParameters(bodyParameters: [String: Any], bodyEncoding: ParameterEncoding, urlParameters: [String: Any])
    
    /// A file upload task.
    // case uploadFile(URL)
    
    /// A "multipart/form-data" upload task.
    case uploadMultipart(imageData: Data)
    
    /// A "multipart/form-data" upload task  combined with url parameters.
    // case uploadCompositeMultipart([MultipartFormData], urlParameters: [String: Any])
}
