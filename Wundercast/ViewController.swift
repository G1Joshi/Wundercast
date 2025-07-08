//
//  ViewController.swift
//  Wundercast
//
//  Created by Jeevan Chandra Joshi on 23/06/25.
//

import CoreLocation
import MapKit
import RxCocoa
import RxSwift
import UIKit

typealias Weather = ApiController.Weather

class ViewController: UIViewController {
    private let keyButton = UIButton()
    private let geoLocationButton = UIButton()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let searchCityName = UITextField()
    private let tempLabel = UILabel()
    private let humidityLabel = UILabel()
    private let iconLabel = UILabel()
    private let cityNameLabel = UILabel()

    private var cache = [String: Weather]()
    private let bag = DisposeBag()
    private let locationManager = CLLocationManager()

    var keyTextField: UITextField?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        style()
        setupBindings()
    }

    private func setupUI() {
        searchCityName.placeholder = "City's Name"
        searchCityName.textAlignment = .center
        searchCityName.font = UIFont.boldSystemFont(ofSize: 32)
        searchCityName.returnKeyType = .search
        view.addSubview(searchCityName)

        tempLabel.font = UIFont.systemFont(ofSize: 24)
        tempLabel.textAlignment = .center
        view.addSubview(tempLabel)

        humidityLabel.font = UIFont.systemFont(ofSize: 24)
        humidityLabel.textAlignment = .right
        view.addSubview(humidityLabel)

        iconLabel.font = UIFont(name: "Flaticon", size: 220)
        iconLabel.textAlignment = .center
        view.addSubview(iconLabel)

        cityNameLabel.font = UIFont.systemFont(ofSize: 32)
        cityNameLabel.textAlignment = .center
        view.addSubview(cityNameLabel)

        geoLocationButton.setImage(UIImage(named: "place-location"), for: .normal)
        view.addSubview(geoLocationButton)

        keyButton.setImage(UIImage(named: "key"), for: .normal)
        view.addSubview(keyButton)

        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)

        addConstraints()
    }

    private func addConstraints() {
        searchCityName.translatesAutoresizingMaskIntoConstraints = false
        tempLabel.translatesAutoresizingMaskIntoConstraints = false
        humidityLabel.translatesAutoresizingMaskIntoConstraints = false
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        cityNameLabel.translatesAutoresizingMaskIntoConstraints = false
        geoLocationButton.translatesAutoresizingMaskIntoConstraints = false
        keyButton.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            searchCityName.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            searchCityName.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchCityName.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchCityName.heightAnchor.constraint(equalToConstant: 39),

            iconLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            iconLabel.widthAnchor.constraint(equalTo: iconLabel.heightAnchor),

            tempLabel.leadingAnchor.constraint(equalTo: iconLabel.leadingAnchor),
            tempLabel.bottomAnchor.constraint(equalTo: iconLabel.topAnchor, constant: -8),

            humidityLabel.trailingAnchor.constraint(equalTo: iconLabel.trailingAnchor),
            humidityLabel.bottomAnchor.constraint(equalTo: iconLabel.topAnchor, constant: -8),

            cityNameLabel.topAnchor.constraint(equalTo: iconLabel.bottomAnchor, constant: 8),
            cityNameLabel.centerXAnchor.constraint(equalTo: iconLabel.centerXAnchor),

            geoLocationButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            geoLocationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            geoLocationButton.widthAnchor.constraint(equalToConstant: 44),
            geoLocationButton.heightAnchor.constraint(equalToConstant: 44),

            keyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            keyButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            keyButton.widthAnchor.constraint(equalToConstant: 44),
            keyButton.heightAnchor.constraint(equalToConstant: 44),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupBindings() {
        if RxReachability.shared.startMonitor("apple.com") == false {
            print("Reachability failed!")
        }

        keyButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.requestKey()
            })
            .disposed(by: bag)

        let currentLocation = locationManager.rx.didUpdateLocations
            .map { locations in locations[0] }
            .filter { location in
                location.horizontalAccuracy == kCLLocationAccuracyNearestTenMeters
            }

        let geoInput = geoLocationButton.rx.tap
            .do(onNext: { [weak self] _ in
                self?.locationManager.requestWhenInUseAuthorization()
                self?.locationManager.startUpdatingLocation()

                self?.searchCityName.text = "Current Location"
            })

        let geoLocation = geoInput.flatMap {
            currentLocation.take(1)
        }

        let geoSearch = geoLocation.flatMap { location in
            ApiController.shared.currentWeather(at: location.coordinate)
                .catchAndReturn(.empty)
        }

        let maxAttempts = 4

        let retryHandler: (Observable<Error>) -> Observable<Int> = { e in
            e.enumerated().flatMap { attempt, error -> Observable<Int> in
                if attempt >= maxAttempts - 1 {
                    return Observable.error(error)
                } else if let casted = error as? ApiController.ApiError, casted == .invalidKey {
                    return ApiController.shared.apiKey
                        .filter { !$0.isEmpty }
                        .map { _ in 1 }
                } else if (error as NSError).code == -1009 {
                    return RxReachability.shared.status
                        .filter { $0 == .online }
                        .map { _ in 1 }
                }

                print("== retrying after \(attempt + 1) seconds ==")
                return Observable<Int>.timer(.seconds(attempt + 1),
                                             scheduler: MainScheduler.instance)
                    .take(1)
            }
        }

        let searchInput = searchCityName.rx.controlEvent(.editingDidEndOnExit)
            .map { [weak self] _ in self?.searchCityName.text ?? "" }
            .filter { !$0.isEmpty }

        let textSearch = searchInput.flatMap { text in
            ApiController.shared.currentWeather(city: text)
                .retry(when: retryHandler)
                .cache(key: text, in: \.cache, of: self)
                .catch { [weak self] _ in
                    return Observable.just(self?.cache[text] ?? .empty)
                }
        }

        let search = Observable.merge(geoSearch, textSearch)
            .asDriver(onErrorJustReturn: .empty)

        let running = Observable.merge(searchInput.map { _ in true },
                                       geoInput.map { _ in true },
                                       search.map { _ in false }.asObservable())
            .startWith(true)
            .asDriver(onErrorJustReturn: false)

        search.map { "\($0.temperature)° C" }
            .drive(tempLabel.rx.text)
            .disposed(by: bag)

        search.map(\.icon)
            .drive(iconLabel.rx.text)
            .disposed(by: bag)

        search.map { "\($0.humidity)%" }
            .drive(humidityLabel.rx.text)
            .disposed(by: bag)

        search.map(\.cityName)
            .drive(cityNameLabel.rx.text)
            .disposed(by: bag)

        running.skip(1).drive(activityIndicator.rx.isAnimating).disposed(by: bag)
        running.drive(tempLabel.rx.isHidden).disposed(by: bag)
        running.drive(iconLabel.rx.isHidden).disposed(by: bag)
        running.drive(humidityLabel.rx.isHidden).disposed(by: bag)
        running.drive(cityNameLabel.rx.isHidden).disposed(by: bag)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        Appearance.applyBottomLine(to: searchCityName)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    func requestKey() {
        func configurationTextField(textField: UITextField!) {
            keyTextField = textField
        }

        let alert = UIAlertController(title: "Api Key",
                                      message: "Add the api key:",
                                      preferredStyle: .alert)

        alert.addTextField(configurationHandler: configurationTextField)

        alert.addAction(UIAlertAction(title: "Ok", style: .default) { [weak self] _ in
            ApiController.shared.apiKey.onNext(self?.keyTextField?.text ?? "")
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive))

        present(alert, animated: true)
    }

    private func style() {
        view.backgroundColor = UIColor.aztec
        searchCityName.textColor = UIColor.ufoGreen
        tempLabel.textColor = UIColor.cream
        humidityLabel.textColor = UIColor.cream
        iconLabel.textColor = UIColor.cream
        cityNameLabel.textColor = UIColor.cream
    }
}
