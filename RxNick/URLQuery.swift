//
//  URLQuery.swift
//  RxNick
//
//  Created by Isaac Weisberg on 11/19/18.
//  Copyright © 2018 Isaac Weisberg. All rights reserved.
//

import Foundation

public protocol URLQuery {
    var items: [URLQueryItem] { get }
}

extension Array: URLQuery where Element == URLQueryItem {
    public var items: [URLQueryItem] {
        return self
    }
}
