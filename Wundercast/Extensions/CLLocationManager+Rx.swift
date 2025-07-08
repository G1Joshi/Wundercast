//
//  CLLocationManager+Rx.swift
//  Wundercast
//
//  Created by Jeevan Chandra Joshi on 08/07/25.
//

import CoreLocation
import Foundation
import RxCocoa
import RxSwift

class RxCLLocationManagerDelegateProxy: DelegateProxy<CLLocationManager, CLLocationManagerDelegate>, DelegateProxyType, CLLocationManagerDelegate {
    public init(locationManager: CLLocationManager) {
        super.init(parentObject: locationManager, delegateProxy: RxCLLocationManagerDelegateProxy.self)
    }

    static func registerKnownImplementations() {
        register { RxCLLocationManagerDelegateProxy(locationManager: $0) }
    }

    static func currentDelegate(for object: CLLocationManager) -> CLLocationManagerDelegate? {
        let locationManager: CLLocationManager = object
        return locationManager.delegate
    }

    static func setCurrentDelegate(_ delegate: CLLocationManagerDelegate?, to object: CLLocationManager) {
        let locationManager: CLLocationManager = object
        locationManager.delegate = delegate
    }
}

public extension Reactive where Base: CLLocationManager {
    var delegate: DelegateProxy<CLLocationManager, CLLocationManagerDelegate> {
        return RxCLLocationManagerDelegateProxy.proxy(for: base)
    }

    var didUpdateLocations: Observable<[CLLocation]> {
        return delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:didUpdateLocations:)))
            .map { a in
                a[1] as! [CLLocation]
            }
    }
}
