//
//  API.swift
//  GitHubSearch
//
//  Created by Yuhei Kikuchi on 2018/02/08.
//  Copyright © 2018 Yuhei Kikuchi. All rights reserved.
//

import Foundation

//--------------------------------------------------------------------------

enum JSONDecodeError: Error {
    case MissingRequiredKey(String)
    case UnexpectedType(key: String, expected: Any, actutal: Any)
}

struct JSONObject {
    let JSON: [String : AnyObject]

    func get<T>(_ key: String) throws -> T {
        guard let value = JSON[key] else {
            throw JSONDecodeError.MissingRequiredKey(key)
        }

        guard let typedValue = value as? T else {
            throw JSONDecodeError.UnexpectedType(key      : key,
                                                 expected : String(describing: T.self),
                                                 actutal  : value.type)
        }

        return typedValue
    }

    func get<T>(_ key: String) throws -> T? {
        guard let value = JSON[key] else {
            return nil
        }

        if value is NSNull {
            return nil
        }

        guard let typedValue = value as? T else {
            throw JSONDecodeError.UnexpectedType(key      : key,
                                                 expected : String(describing: T.self),
                                                 actutal  : value.type)
        }

        return typedValue
    }
}

// MARK: WebAPI
protocol JSONDecodable {
    init(JSON: JSONObject) throws
}

struct SearchResult<ItemType: JSONDecodable>: JSONDecodable {
    let total_count        : Int
    let incomplete_results : Bool
    let items              : [ItemType]

    init(JSON: JSONObject) throws {
        self.total_count        = try JSON.get("total_count")
        self.incomplete_results = try JSON.get("incomplete_results")
        self.items              = try JSON.get("items")
    }
}

struct Repository: JSONDecodable {
    let id                : Int
    let name              : String
    let full_name         : String
    let owner             : Owner
    let is_private        : Bool
    let html_url          : URL
    let description       : String?
    let fork              : Bool
    let url               : URL
    let created_at        : Date
    let updated_at        : Date
    let pushed_at         : Date?
    let homepage          : String?
    let size              : Int
    let stargazers_count  : Int
    let watchers_count    : Int
    let language          : String?
    let forks_count       : Int
    let open_issues_count : Int
    let default_branch    : String
    let score             : Double

    init(JSON: JSONObject) throws {
        self.id                = try JSON.get("id")
        self.name              = try JSON.get("name")
        self.full_name         = try JSON.get("full_name")
        self.owner             = try JSON.get("owner")
        self.is_private        = try JSON.get("is_private")
        self.html_url          = try JSON.get("html_url")
        self.description       = try JSON.get("description") as String
        self.fork              = try JSON.get("fork")
        self.url               = try JSON.get("url")
        self.created_at        = try JSON.get("created_at")
        self.updated_at        = try JSON.get("updated_at")
        self.pushed_at         = try JSON.get("pushed_at") as Date
        self.homepage          = try JSON.get("homepage") as String
        self.size              = try JSON.get("size")
        self.stargazers_count  = try JSON.get("stargazers_count")
        self.watchers_count    = try JSON.get("watchers_count")
        self.language          = try JSON.get("language") as String
        self.forks_count       = try JSON.get("forks_count")
        self.open_issues_count = try JSON.get("open_issues_count")
        self.default_branch    = try JSON.get("default_branch")
        self.score             = try JSON.get("score")
    }
}

struct Owner: JSONDecodable {
    let login             : String
    let id                : Int
    let avaterURL         : URL
    let gravatarID        : String
    let url               : URL
    let receivedEventsURL : URL
    let type              : String

    init(JSON: JSONObject) throws {
        self.login             = try! JSON.get("login")
        self.id                = try! JSON.get("id")
        self.avaterURL         = URL(string: try! JSON.get("avaterURL"))!
        self.gravatarID        = try! JSON.get("gravatarID")
        self.url               = URL(string: try! JSON.get("url"))!
        self.receivedEventsURL = URL(string: try! JSON.get("receivedEventsURL"))!
        self.type              = try JSON.get("type")
    }
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

    var urlRequest: NSURLRequest {
        var components = URLComponents(url: url,
                                       resolvingAgainstBaseURL: true)
        components?.queryItems = query?.map(URLQueryItem.init)

        let req = NSMutableURLRequest(url: components?.url ?? url)
        req.httpMethod = method.rawValue

        for (key, value) in headers ?? [:] {
            req.addValue(value, forHTTPHeaderField: key)
        }

        return req
    }
}

enum APIError : Error {
    case EmptyBody
    case UnexpectedResponseType
}

enum APIResult<Response> {
    case Success(Response)
    case Failure(Error)
}

extension APIEndpoint {
    func request(session: URLSession,
                 callback: @escaping (APIResult<ResponseType>) -> Void) -> URLSessionDataTask {
        let task = session.dataTask(with: urlRequest as URLRequest) { (data, response, error) in
            if let e = error {
                callback(.Failure(e))
            } else if let data = data {
                do {
                    guard let dic = try JSONSerialization.jsonObject(with: data, options: []) as? [String : AnyObject] else {
                        throw APIError.UnexpectedResponseType
                    }

                    let response = try ResponseType(JSON: JSONObject(JSON: dic))
                    callback(.Success(response))
                } catch {
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

protocol GitHubEndpoint : APIEndpoint {
    var path: String { get }
}

private let GitHubURL = URL(string: "https://api.github.com")

extension GitHubEndpoint {
    var url: URL {
        return URL(string: path, relativeTo: GitHubURL)!
    }

    var headers: [String : String]? {
        return [ "Accept" : "application/vnd.github.v3+json" ]
    }
}

struct SearchRepositories : GitHubEndpoint {
    var path = "search/repositories"
    typealias ResponseType = SearchResult<Repository>
    var query: [String : String]? {
        return [ "q"    : searchQuery,
                 "page" : String(page) ]
    }

    let searchQuery: String
    let page: Int
    init(searchQuery: String, page: Int) {
        self.searchQuery = searchQuery
        self.page = page
    }
}




