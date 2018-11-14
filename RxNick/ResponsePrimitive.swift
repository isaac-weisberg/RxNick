//
//  ResponsePrimitive.swift
//  RxNick
//
//  Created by Isaac Weisberg on 11/14/18.
//  Copyright © 2018 Isaac Weisberg. All rights reserved.
//

import Foundation

public class ResponsePrimitive<Trait: ResponseTrait> {
    public let res: HTTPURLResponse
    public let data: Data?
    
    init(res: HTTPURLResponse, data: Data?) {
        self.res = res
        self.data = data
    }
    
    public func ensureStatusCode(in union: StatusCodeRange) throws {
        let code = res.statusCode
        guard union.contains(where: { $0.contains(code) }) else {
            throw NickError.statusCode(code, union)
        }
    }
    
    public func json<Target: Decodable>() throws -> Target {
        let data = try ensureData()
        do {
            return try JSONDecoder().decode(Target.self, from: data)
        } catch {
            throw NickError.parsing(error)
        }
    }
    
    public func ensureData() throws -> Data {
        guard let data = data else {
            throw NickError.expectedData
        }
        return data
    }
}

public typealias ResponseFresh = ResponsePrimitive<FreshResponseTrait>

public protocol ResponseTrait {
    
}

public struct FreshResponseTrait: ResponseTrait {
    
}
