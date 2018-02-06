//
//  APIRequest.swift
//  GitHubSearch
//
//  Created by Yuhei Kikuchi on 2018/02/05.
//  Copyright © 2018 Yuhei Kikuchi. All rights reserved.
//

import Foundation

class APIRequest {

    static let GITHUB_API: String = "https://api.github.com/search/repositories?q=Hatena&page=1"
    let GITHUB_URL = URL(string: GITHUB_API)!

    // MARK: Struct
    struct Owner {
        let login             : String
        let id                : Int
        let avaterURL         : URL
        let gravatarID        : String
        let url               : URL
        let receivedEventsURL : URL
        let type              : String

        init?(JSON: [String : AnyObject]) {
            guard
                let login             = JSON["login"]              as? String,
                let id                = JSON["id"]                 as? Int,
                let avaterURL         = (JSON["avaterURL"]         as? String).flatMap(URL.init(string:)),
                let gravatarID        = JSON["gravatarID"]         as? String,
                let url               = (JSON["url"]               as? String).flatMap(URL.init(string:)),
                let receivedEventsURL = (JSON["receivedEventsURL"] as? String).flatMap(URL.init(string:)),
                let type              = JSON["type"]               as? String
                else {
                    return nil
            }

            self.login             = login
            self.id                = id
            self.avaterURL         = avaterURL
            self.gravatarID        = gravatarID
            self.url               = url
            self.receivedEventsURL = receivedEventsURL
            self.type              = type
        }

        init(JSON: JSONObject) {
            self.login             = try! JSON.get("login")
            self.id                = try! JSON.get("id")
            self.avaterURL         = URL(string: try! JSON.get("avaterURL"))!
            self.gravatarID        = try! JSON.get("gravatarID")
            self.url               = URL(string: try! JSON.get("url"))!
            self.receivedEventsURL = URL(string: try! JSON.get("receivedEventsURL"))!
            self.type              = try! JSON.get("type")
        }
    }

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
                throw JSONDecodeError.UnexpectedType(key: key,
                                                     expected: String(describing: T.self),
                                                     actutal: value.type)
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
                throw JSONDecodeError.UnexpectedType(key: key,
                                                     expected: String(describing: T.self),
                                                     actutal: value.type)
            }

            return typedValue
        }
    }


    // MARK: Initializer
    init() {
        LogUtil.traceFunc()
        request()
    }

    // MARK: Private
    private func request() {
        LogUtil.traceFunc()

        var request = URLRequest(url: GITHUB_URL)
        request.httpMethod = "GET"
        request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                LogUtil.error(error)
            }

            // let data: NSData!
            var JSON: [String : AnyObject]?
            JSON = try! JSONSerialization.jsonObject(with: data!, options: []) as? [String : AnyObject]

            if let JSON = JSON {
                if let items = JSON["items"] as? [AnyObject] {
                    for case let item as [String : AnyObject] in items {
                        if let name = item["name"] as? String {
                            LogUtil.debug(name)
                            print(name)
                        }
                    }
                }
            }
        }

        task.resume()
    }
}
