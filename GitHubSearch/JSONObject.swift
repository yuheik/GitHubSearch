//
//  JSONObject.swift
//  GitHubSearch
//
//  Created by Yuhei Kikuchi on 2018/02/08.
//  Copyright © 2018 Yuhei Kikuchi. All rights reserved.
//

protocol JSONDecodable {
    init(JSON: JSONObject) throws
}

enum JSONDecodeError: ErrorType, CustomDebugStringConvertible {
    case MissingRequiredKey(String)
    case UnexpectedType(key: String, expected: Any, actual: Any.Type)
    case UnexpectedValue(key: String, value: Any, message: String?)

    var debugDescription: String {
        switch self {
        case .MissingRequiredKey(let key):
            return "JSON Decode Error: Required key '\(key)' missing"
        case let .UnexpectedType(key: key, expected: expected, actual: actual):
            return "JSON Decode Error: Unexpected type '\(actual)' was supplied for '\(key): \(expected)'"
        case let .UnexpectedValue(key: key, value: value, message: message):
            return "JSON Decode Error: \(message ?? "Unexpected value") '\(value)' was supplied for '\(key)'"
        }
    }
}

protocol JSONValueConverter {
    associatedtype FromType
    associatedtype ToType

    func convert(key: String, value: FromType) throws -> ToType
}

struct DefaultConverter<T>: JSONValueConverter {
    typealias FromType = T
    typealias ToType = T

    func convert(key: String, value: FromType) -> DefaultConverter.ToType {
        return value
    }
}

struct ObjectConverter<T: JSONDecodable>: JSONValueConverter {
    typealias FromType = [String : AnyObject]
    typealias ToType = T

    func convert(key: String, value: FromType) throws -> ObjectConverter.ToType {
        return try T(JSON: JSONObject(JSON: value))
    }
}

struct ArrayConverter<T: JSONDecodable>: JSONValueConverter {
    typealias FromType = [[String : AnyObject]]
    typealias ToType = [T]

    func convert(key: String, value: FromType) throws -> ArrayConverter.ToType {
        return try value.map(JSONObject.init).map(T.init)
    }
}

// MARK: JSON Primitive Values

protocol JSONPrimitive {}

extension String: JSONPrimitive {}
extension Int: JSONPrimitive {}
extension Double: JSONPrimitive {}
extension Bool: JSONPrimitive {}

// MARK: Types that could be coverted by using JSONValueConverter

protocol JSONConvertible {
    associatedtype ConverterType: JSONValueConverter
    static var converter: ConverterType { get }
}

// MARK: JSONObject

struct JSONObject {
    let JSON: [String : AnyObject]

    init(JSON: [String : AnyObject]) {
        self.JSON = JSON
    }

    func get<Converter: JSONValueConverter>(key: String, converter: Converter) throws -> Converter.ToType {
        guard let value = JSON[key] else {
            throw JSONDecodeError.MissingRequiredKey(key)
        }

        guard let typedValue = value as? Converter.FromType else {
            throw JSONDecodeError.UnexpectedType(key      : key,
                                                 expected : Converter.FromType.self,
                                                 actual  : value.dynamicType)
        }

        return try converter.convert(key: key, value: typedValue)
    }

    func get<Converter: JSONValueConverter>(key: String, converter: Converter) throws -> Converter.ToType? {
        guard let value = JSON[key] else {
            return nil
        }

        if value is NSNull {
            return nil
        }

        guard let typedValue = value as? Converter.FromType else {
            throw JSONDecodeError.UnexpectedType(key      : key,
                                                 expected : Converter.FromType.self,
                                                 actual   : value.dynamicType)
        }

        return try converter.convert(key: key, value: typedValue)
    }

    func get<T: JSONPrimitive>(key: String) throws -> T {
        return try get(key, converter: DefaultConverter)
    }

    func get<T: JSONPrimitive>(key: String) throws -> T? {
        return try get(key, converter: DefaultConverter)
    }

    func get<T: JSONConvertible where T == T.ConverterType.ToType>(key: String) throws -> T {
        return try get(key, converter: T.converter)
    }

    func get<T: JSONConvertible where T == T.ConverterType.ToType>(key: String) throws -> T? {
        return try get(key, converter: T.converter)
    }

    func get<T: JSONDecodable>(key: String) throws -> T {
        return try get(key, converter: ObjectConverter())
    }

    func get<T: JSONDecodable>(key: String) throws -> T? {
        return try get(key, converter: ObjectConverter())
    }

    func get<T: JSONDecodable>(key: String) throws -> [T] {
        return try get(key, converter: ArrayConverter())
    }

    func get<T: JSONDecodable>(key: String) throws -> [T]? {
        return try get(key, converter: ArrayConverter())
    }
}

// MARK: Expansion for Foundation

import Foundation

extension NSURL: JSONConvertible {
    typealias ConverterType = URLConverter
    static var converter: ConverterType {
        return URLConverter
    }
}

extension NSDate: JSONConvertible {
    typealias ConverterType = DateConverter
    static var converter: ConverterType {
        return DateConverter()
    }
}

struct URLConverter: JSONValueConverter {
    typealias FromType = String
    typealias ToType = NSURL

    func convert(key key: String, value: FromType) throws -> URLConverter.ToType {
        guard let URL = NSURL(string: value) else {
            throw JSONDecodeError.UnexpectedValue(key: key, value: value, message: "Invalid URL")
        }
        return URL
    }
}

struct DateConverter: JSONValueConverter {
    typealias FromType = NSTimeInterval
    typealias ToType = NSDate

    func convert(key key: String, value: FromType) -> DateConverter.ToType {
        return NSDate(timeIntervalSince1970: value)
    }
}

