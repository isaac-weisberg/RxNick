//
//  RxNick.swift
//  RxNick
//
//  Created by Isaac Weisberg on 10/27/18.
//  Copyright © 2018 Isaac Weisberg. All rights reserved.
//

import Foundation
import RxSwift

public class Response {
    public let res: HTTPURLResponse
    public let data: Data?
    
    init(res: HTTPURLResponse, data: Data?) {
        self.res = res
        self.data = data
    }
}

func request(_ req: URLRequest, session: URLSession = URLSession.shared) -> Single<Response> {
    return Single.create { single in
        var task: URLSessionDataTask? = session.dataTask(with: req) { data, response, error in
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
