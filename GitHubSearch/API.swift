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
    var url                     : URL                { get }
    var method                  : HTTPMethod         { get }
    var query                   : [String : String]? { get }
    var headers                 : [String : String]? { get }
    associatedtype ResponseType : JSONDecodable
}

extension APIEndpoint {
    var method  : HTTPMethod         { return .GET }
    var query   : [String : String]? { return nil  }
    var headers : [String : String]? { return nil  }
}

extension APIEndpoint {
    private var URLRequest: NSURLRequest {
        let components = NSURLComponents(url: url,
                                         resolvingAgainstBaseURL: true)
        components?.queryItems = query?.map(URLQueryItem.init)

        let req = NSMutableURLRequest(url: components?.url ?? url)
        req.httpMethod = method.rawValue

        for (key, value) in headers ?? [:] {
            req.addValue(value, forHTTPHeaderField: key)
        }

        return req
    }

    func request(session: URLSession,
                 callback: @escaping (APIResult<ResponseType>) -> Void) -> URLSessionDataTask {
        LogUtil.traceFunc(className: "APIEndpoint")

        let task = session.dataTask(with: URLRequest as URLRequest) { (data, response, error) in
            if let e = error {
                LogUtil.error(e)
                callback(.Failure(e))
            } else if let data = data {
                do {
                    guard let dic = try JSONSerialization.jsonObject(with: data, options: []) as? [String : AnyObject] else {
                        LogUtil.debug("unexpected response type")
                        throw APIError.UnexpectedResponseType
                    }

                    let response = try ResponseType(JSON: JSONObject(JSON: dic))
                    print(response)
                    print(dic)
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



