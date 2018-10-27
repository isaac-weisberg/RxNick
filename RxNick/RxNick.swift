//
//  RxNick.swift
//  RxNick
//
//  Created by Isaac Weisberg on 10/27/18.
//  Copyright © 2018 Isaac Weisberg. All rights reserved.
//

import Foundation
import RxSwift

func encode<Body: Encodable>(_ body: Body) throws -> Data {
    do {
        return try JSONEncoder().encode(body)
    } catch {
        throw RxNick.NickError.parsing(error)
    }
}

public extension RxNick {
    public enum Method: String {
        case GET
        case POST
    }
}

public extension RxNick {
    public enum NickError: Error {
        case parsing(Error)
        case expectedData
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
    let session: URLSession
    
    public init(_ session: URLSession = URLSession.shared) {
        self.session = session
    }
    
    public func request(_ request: URLRequest) -> Single<Response> {
        return Single.create {[session = session] single in
            var task: URLSessionDataTask? = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    single(.error(error))
                    return
                }
                
                let response = response as! HTTPURLResponse
                let resp = Response(res: response, data: data)
                single(.success(resp))
            }
            
            return Disposables.create {
                task?.cancel()
                task = nil
            }
        }
    }
    
    public func get(_ url: URL) -> Single<Response> {
        let req = URLRequest(url: url)
        return request(req)
    }
    
    public func post(_ url: URL, data: Data?) -> Single<Response> {
        var req = URLRequest(url: url)
        req.httpMethod = Method.POST.rawValue
        req.httpBody = data
        return request(req)
    }
    
    func post<Body: Encodable>(_ url: URL, body: Body) -> Single<Response> {
        return Single<URLRequest>.deferred {
            var req = URLRequest(url: url)
            req.httpMethod = Method.POST.rawValue
            req.httpBody = try encode(body)
            return .just(req)
        }.flatMap {[request = request] req in
            request(req)
        }
    }
}
