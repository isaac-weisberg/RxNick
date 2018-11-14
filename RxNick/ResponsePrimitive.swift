//
//  ResponsePrimitive.swift
//  RxNick
//
//  Created by Isaac Weisberg on 11/14/18.
//  Copyright © 2018 Isaac Weisberg. All rights reserved.
//

import Foundation

public protocol ResponsePrimitive {
    var res: HTTPURLResponse { get }
}

public extension ResponsePrimitive {
    public func ensureStatusCode(in union: StatusCodeRange) throws {
        let code = res.statusCode
        guard union.contains(where: { $0.contains(code) }) else {
            throw NickError.statusCode(code, union)
        }
    }
}

public class FreshResponse: ResponsePrimitive {
    public let res: HTTPURLResponse
    public let data: Data?
    
    init(res: HTTPURLResponse, data: Data?) {
        self.res = res
        self.data = data
    }
    
    public func json<Target: Decodable>() throws -> Response<Target> {
        let data = try ensureData()
        let decoder = JSONDecoder()
        let object: Target
        do {
            object = try decoder.decode(Target.self, from: data)
        } catch {
            throw NickError.parsing(error)
        }
        return Response(res: res, data: data, object: object)
    }
    
    public func ensureData() throws -> Data {
        guard let data = data else {
            throw NickError.expectedData
        }
        return data
    }
}

public class Response<Object: Decodable>: ResponsePrimitive {
    public let res: HTTPURLResponse
    public let data: Data
    public let object: Object
    
    init(res: HTTPURLResponse, data: Data, object: Object) {
        self.res = res
        self.data = data
        self.object = object
    }
}
