//
//  Appearance.swift
//  Wundercast
//
//  Created by Jeevan Chandra Joshi on 08/07/25.
//

import Foundation
import UIKit

public enum Appearance {
    static func applyBottomLine(to view: UIView, color: UIColor = UIColor.ufoGreen) {
        let line = UIView(frame: CGRect(x: 0, y: view.frame.height - 1, width: view.frame.width, height: 1))
        line.backgroundColor = color
        view.addSubview(line)
    }
}
