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

    let githubURL = URL(string: GITHUB_API)!

    init() {
        LogUtil.traceFunc()

        var request = URLRequest(url: githubURL)
        request.httpMethod = "GET"
        request.addValue("application/vnd.github.v3+josn", forHTTPHeaderField: "Accept")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                LogUtil.error(error)
            }

            // let data: NSData!
            var JSON: [String : AnyObject]?
            //do {
                JSON = try! JSONSerialization.jsonObject(with: data!, options: []) as? [String : AnyObject]
//            } catch {
//                print(error)
//            }

            if let JSON = JSON {
                if let items = JSON["items"] as? [AnyObject] {
                    for case let item as [String: AnyObject] in items {
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



