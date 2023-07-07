//
//  FLTUnityView.swift
//  flutter_unity_widget
//
//  Created by Rex Raphael on 30/01/2021.
//

import Foundation
import UIKit
import UnityFramework

class FLTUnityView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        if (!self.bounds.isEmpty) {
            GetUnityPlayerUtils().ufw?.appController()?.rootView.frame = self.bounds
        }
    }
}
