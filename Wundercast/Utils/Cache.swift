//
//  Cache.swift
//  Wundercast
//
//  Created by Jeevan Chandra Joshi on 08/07/25.
//

import RxSwift

extension ObservableType where Element == Weather {
    func cache<T: UIViewController>(key: String, in target: WritableKeyPath<T, [String: Weather]>, of viewController: T) -> Observable<Element> {
        return observe(on: MainScheduler.instance)
            .do(onNext: { [weak viewController] data in
                    if var vc = viewController {
                        vc[keyPath: target][key] = data
                    }
                },
                onError: { [weak viewController] e in
                    guard let vc = viewController else {
                        return
                    }
                    guard let e = e as? ApiController.ApiError else {
                        InfoView.showIn(viewController: vc, message: "An error occurred")
                        return
                    }

                    switch e {
                    case .cityNotFound:
                        InfoView.showIn(viewController: vc, message: "City Name is invalid")
                    case .serverFailure:
                        InfoView.showIn(viewController: vc, message: "Server error")
                    case .invalidKey:
                        InfoView.showIn(viewController: vc, message: "Key is invalid")
                    }
                })
    }
}
