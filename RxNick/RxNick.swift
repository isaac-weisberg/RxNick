//
//  RxNick.swift
//  RxNick
//
//  Created by Isaac Weisberg on 10/27/18.
//  Copyright © 2018 Isaac Weisberg. All rights reserved.
//

import Foundation
import RxSwift

public extension RxNick {
    enum Method: String {
        case GET
        case POST
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
    }
}


public class RxNick {
    let session: URLSession
    
    init(_ session: URLSession = URLSession.shared) {
        self.session = session
    }
    
    func request(_ request: URLRequest) -> Single<Response> {
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
    
    func get(_ url: URL) -> Single<Response> {
        let req = URLRequest(url: url)
        return request(req)
    }
    
    func post(_ url: URL, data: Data?) -> Single<Response> {
        var req = URLRequest(url: url)
        req.httpMethod = Method.POST.rawValue
        req.httpBody = data
        return request(req)
    }
}
