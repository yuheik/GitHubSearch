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
    var URL                     : URL         { get }
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
    private var URLRequest: URLRequest {
        var components = URLComponents(url: URL as URL, // @todo
                                       resolvingAgainstBaseURL: true)
        components?.queryItems = query?.parameters.map(URLQueryItem.init)

        let req = NSMutableURLRequest(url: components?.url ?? URL)
        req.httpMethod = method.rawValue

        for case let (key, value) in headers?.parameters ?? [:] {
            req.addValue(value!, forHTTPHeaderField: key)
        }

        return req as URLRequest
    }

    func request(session: URLSession,
                 callback: @escaping (APIResult<ResponseType>) -> Void) -> URLSessionDataTask {
        LogUtil.traceFunc(className: "APIEndpoint")

        let task = session.dataTask(with: URLRequest) { (data, response, error) in
            if let e = error {
                LogUtil.error(e)
                callback(.Failure(e))
            } else if let data = data {
                do {
                    guard let dic = try JSONSerialization.jsonObject(with: data, options: []) as? [String : AnyObject] else {
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
    case Failure(Error)
}

struct Parameters: ExpressibleByDictionaryLiteral {
    typealias Key = String
    typealias Value = String?
    private(set) var parameters: [Key: Value] = [:]

    init(dictionaryLiteral elements: (String, String?)...) {
        for case let (key, value?) in elements {
            parameters[key] = value
        }
    }
}

