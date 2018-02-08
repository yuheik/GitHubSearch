//
//  JSONObject.swift
//  GitHubSearch
//
//  Created by Yuhei Kikuchi on 2018/02/08.
//  Copyright © 2018 Yuhei Kikuchi. All rights reserved.
//

import Foundation

protocol JSONDecodable {
    init(JSON: JSONObject) throws
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
