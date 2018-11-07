//
//  RxNick.swift
//  RxNick
//
//  Created by Isaac Weisberg on 10/27/18.
//  Copyright © 2018 Isaac Weisberg. All rights reserved.
//

import Foundation
import RxSwift

func jsonEncode<Body: Encodable>(_ body: Body) throws -> Data {
    do {
        return try JSONEncoder().encode(body)
    } catch {
        throw RxNick.NickError.parsing(error)
    }
}

extension URL {
    func appeding(query: [String: String]) -> URL {
        let optionalComponents = URLComponents(url: self, resolvingAgainstBaseURL: false)
        assert(optionalComponents != nil, "This means that the user has applied a URL with malformed URL string. I literally have no idea what it means, and at this point idc.")
        var components = optionalComponents!
        var urlQuery = components.queryItems ?? []
        urlQuery.append(contentsOf: query.compactMap { pair in
            let (key, value) = pair
            return URLQueryItem(name: key, value: value)
        })
        components.queryItems = urlQuery
        let resultingUrl = components.url
        assert(resultingUrl != nil, "This means that a url was poiting into the file:// scheme and the path was not absolute. Since it's a networking framework, please don't use it to work with the file system")
        return resultingUrl!
    }
}

public extension RxNick {
    public enum Method: String {
        case get = "GET"
        case post = "POST"
    }
}

public extension RxNick {
    public enum NickError: Error {
        case parsing(Error)
        case expectedData
        case networking(Error)
    }
}

public extension RxNick {
    public class Response {
        public let res: HTTPURLResponse
        public let data: Data?
        
        init(res: HTTPURLResponse, data: Data?) {
            self.res = res
            self.data = data
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
}


public class RxNick {
    public typealias Headers = [String: String]
    public typealias URLQuery = [String: String]
    typealias Body = Data
    typealias URLFactory = () -> URL
    typealias BodyFactory = () throws -> Body?
    typealias HeadersFactory = () -> Headers?
    
    let session: URLSession
    
    public init(_ session: URLSession = URLSession.shared) {
        self.session = session
    }
    
    func request(method: Method, urlFactory: @escaping URLFactory, headersFactory: @escaping HeadersFactory, bodyFactory: @escaping BodyFactory) -> Single<Response> {
        return Single.create {[session = session] single in
            var request = URLRequest(url: urlFactory())
            request.httpMethod = method.rawValue
            do {
                request.httpBody = try bodyFactory()
            } catch {
                assert(error is NickError, "Should be already compliant to unified error model")
                single(.error(error))
            }
            request.allHTTPHeaderFields = headersFactory()
            
            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    single(.error(NickError.networking(error)))
                    return
                }
                
                assert(response is HTTPURLResponse, "Since the api used in this callback is the dataTask API, as per Apple docs, this object is always the HTTPURLResponse and thus this assertion.")
                let response = response as! HTTPURLResponse
                let resp = Response(res: response, data: data)
                single(.success(resp))
            }
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    public func get(_ url: URL, query: [String: String]?, headers: Headers?) -> Single<Response> {
        return request(method: .get, urlFactory: {
            guard let query = query else {
                return url
            }
            return url.appeding(query: query)
        }, headersFactory: { headers }, bodyFactory: { nil })
    }
    
    public func post<Object: Encodable>(_ url: URL, object: Object?, headers: Headers?) -> Single<Response> {
        return request(method: .post, urlFactory: { url }, headersFactory: {
            var headers = headers ?? [:]
            headers["Content-Type"] = "application/json"
            return headers
        }, bodyFactory: {
            if let object = object {
                return try jsonEncode(object)
            }
            return nil
        })
    }
}
