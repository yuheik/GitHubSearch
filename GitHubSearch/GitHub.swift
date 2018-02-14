//
//  GitHub.swift
//  GitHubSearch
//
//  Created by Yuhei Kikuchi on 2018/02/08.
//  Copyright © 2018 Yuhei Kikuchi. All rights reserved.
//

import Foundation

protocol GitHubEndpoint : APIEndpoint {
    var path: String { get }
}

private let GitHubURL = URL(string: "https://api.github.com/")

extension GitHubEndpoint {
    var url: URL {
        return Foundation.URL(string: path, relativeTo: GitHubURL)!
    }

    var headers: Parameters {
        return [ "Accept" : "application/vnd.github.v3+json" ]
    }
}

struct SearchRepositories : GitHubEndpoint {
    var path = "search/repositories"
    typealias ResponseType = SearchResult<Repository>
    var query: Parameters? {
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

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: Calendar.Identifier.gregorian)
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    return formatter
}()

struct FormattedDateConverter: JSONValueConverter {
    typealias FromType = String
    typealias ToType = Date

    private let dateFormatter: DateFormatter

    func convert(key: String, value: FromType) throws -> DateConverter.ToType {
        guard let date = dateFormatter.date(from: value) else {
            throw JSONDecodeError.UnexpectedValue(key: key,
                                                  value: value,
                                                  message: "Invalid date format for '\(dateFormatter.dateFormat)'")
        }
        return date
    }
}

struct SearchResult<ItemType: JSONDecodable>: JSONDecodable {
    let total_count        : Int
    let incomplete_results : Bool
    let items              : [ItemType]

    init(JSON: JSONObject) throws {
        LogUtil.traceFunc(className: "SearchResult")

        self.total_count        = try JSON.get("total_count")

        LogUtil.debug("\(total_count)")
        self.incomplete_results = try JSON.get("incomplete_results")
        LogUtil.debug("\(incomplete_results)")
        self.items              = try JSON.get("items")
        LogUtil.debug("C")

        LogUtil.traceFunc(className: "SearchResult", message: "done")
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
        LogUtil.traceFunc(className: "Repository")
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
        self.pushed_at         = try JSON.get("pushed_at", converter: FormattedDateConverter(dateFormatter: dateFormatter)) as Date
        self.homepage          = try JSON.get("homepage") as String
        self.size              = try JSON.get("size")
        self.stargazers_count  = try JSON.get("stargazers_count")
        self.watchers_count    = try JSON.get("watchers_count")
        self.language          = try JSON.get("language") as String
        self.forks_count       = try JSON.get("forks_count")
        self.open_issues_count = try JSON.get("open_issues_count")
        self.default_branch    = try JSON.get("default_branch")
        self.score             = try JSON.get("score")

        LogUtil.traceFunc(className: "Repository", message: "done")
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
        LogUtil.traceFunc(className: "Owner")

        self.login             = try JSON.get("login")
        self.id                = try JSON.get("id")
        self.avaterURL         = try JSON.get("avaterURL", converter: FormattedDateConverter(dateFormatter: dateFormatter))
        self.gravatarID        = try JSON.get("gravatarID")
        self.url               = try JSON.get("url")
        self.receivedEventsURL = try JSON.get("receivedEventsURL")
        self.type              = try JSON.get("type")

        LogUtil.traceFunc(className: "Owner", message: "done")
    }
}
