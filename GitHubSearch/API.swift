//
//  API.swift
//  GitHubSearch
//
//  Created by Yuhei Kikuchi on 2018/02/08.
//  Copyright © 2018 Yuhei Kikuchi. All rights reserved.
//

import Foundation

enum APIError : Error {
    case EmptyBody
    case UnexpectedResponseType
}

enum HTTPMethod: String {
    case OPTIONS
    case GET
    case HEAD
    case POST
    case PUT
    case DELETE
    case TRACE
    case CONNECT
}

protocol APIEndpoint {
    var URL                     : NSURL       { get }
    var method                  : HTTPMethod  { get }
    var query                   : Parameters? { get }
    var headers                 : Parameters? { get }
    associatedtype ResponseType : JSONDecodable
}

extension APIEndpoint {
    var method  : HTTPMethod  { return .GET }
    var query   : Parameters? { return nil  }
    var headers : Parameters? { return nil  }
}

extension APIEndpoint {
    private var URLRequest: NSURLRequest {
        let components = NSURLComponents(url: URL as URL, // @todo
                                         resolvingAgainstBaseURL: true)
        components?.queryItems = query?.parameters.map(NSURLQueryItem.init)

        let req = NSMutableURLRequest(URL: components?.url ?? URL)
        req.httpMethod = method.rawValue

        for case let (key, value) in headers?.parameters ?? [:] {
            req.addValue(value, forHTTPHeaderField: key)
        }

        return req
    }

    func request(session: NSURLSession,
                 callback: @escaping (APIResult<ResponseType>) -> Void) -> NSURLSessionDataTask {
        LogUtil.traceFunc(className: "APIEndpoint")

        let task = session.dataTaskWithRequest(URLRequest) { (data, response, error) in
            if let e = error {
                LogUtil.error(e)
                callback(.Failure(e))
            } else if let data = data {
                do {
                    guard let dic = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String : AnyObject] else {
                        LogUtil.debug("unexpected response type")
                        throw APIError.UnexpectedResponseType
                    }

                    print(dic)

                    let response = try ResponseType(JSON: JSONObject(JSON: dic))
                    LogUtil.debug("response")
                    callback(.Success(response))
                } catch {
                    LogUtil.debug("failure")
                    print(error)
                    callback(.Failure(error))
                }
            } else {
                callback(.Failure(APIError.EmptyBody))
            }
        }

        task.resume()
        return task
    }
}

enum APIResult<Response> {
    case Success(Response)
    case Failure(ErrorType)
}

struct Parameters: DictionaryLiteralConvertible {
    typealias Key = Stringnn
    typealias Value = String?
    private(set) var parameters: [Key: Value] = [:]

    init(dictionaryLiteral elements: (String, String?)...) {
        for case let (key, value?) in elements {
            parameters[key] = value
        }
    }
}

