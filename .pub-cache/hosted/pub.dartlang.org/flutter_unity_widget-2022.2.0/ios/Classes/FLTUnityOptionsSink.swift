//
//  FLTUnityOptionsSink.swift
//  flutter_unity_widget
//
//  Created by Rex Raphael on 30/01/2021.
//

import Foundation

// Defines map UI options writable from Flutter.
protocol FLTUnityOptionsSink: AnyObject {
    func setDisabledUnload(enabled: Bool)
}
