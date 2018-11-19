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

extension URLQueryItem: URLQuery {
    public var items: [URLQueryItem] {
        return [self]
    }
}

extension Array: URLQuery where Element: URLQuery {
    public var items: [URLQueryItem] {
        return self.reduce([], { sum, query in
            sum + query.items
        })
    }
}
