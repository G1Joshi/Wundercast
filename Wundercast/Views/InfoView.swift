//
//  InfoView.swift
//  Wundercast
//
//  Created by Jeevan Chandra Joshi on 08/07/25.
//

import UIKit

class InfoView: UIView {
    private let textLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private static var sharedView: InfoView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = UIColor(red: 0.85, green: 0.0, blue: 0.09, alpha: 1.0)
        layer.cornerRadius = 8
        layer.masksToBounds = false
        layer.shadowColor = UIColor.darkGray.cgColor
        layer.shadowOpacity = 0.8
        layer.shadowOffset = CGSize(width: 0, height: 3)

        textLabel.numberOfLines = 0
        textLabel.textAlignment = .left
        textLabel.font = UIFont.systemFont(ofSize: 14)
        textLabel.textColor = .white
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textLabel)

        closeButton.setImage(UIImage(named: "closeSmall"), for: .normal)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(closePressed(_:)), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(closeButton)

        NSLayoutConstraint.activate([
            textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            textLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),
            textLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    static func showIn(viewController: UIViewController, message: String) {
        var displayVC = viewController
        if let tabController = viewController as? UITabBarController {
            displayVC = tabController.selectedViewController ?? viewController
        }

        if sharedView == nil {
            let width = displayVC.view.frame.size.width - 24
            sharedView = InfoView(frame: CGRect(x: 12, y: 0, width: width, height: 60))
        }

        sharedView.textLabel.text = message

        if sharedView.superview == nil {
            let y = displayVC.view.frame.height - sharedView.frame.size.height - 12
            sharedView.frame.origin.y = y
            sharedView.alpha = 0.0

            displayVC.view.addSubview(sharedView)
            sharedView.fadeIn()
            sharedView.perform(#selector(fadeOut), with: nil, afterDelay: 3.0)
        }
    }

    @objc func closePressed(_ sender: UIButton) {
        fadeOut()
    }

    func fadeIn() {
        UIView.animate(withDuration: 0.33) {
            self.alpha = 1.0
        }
    }

    @objc func fadeOut() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        UIView.animate(withDuration: 0.33, animations: {
            self.alpha = 0.0
        }, completion: { _ in
            self.removeFromSuperview()
        })
    }
}
