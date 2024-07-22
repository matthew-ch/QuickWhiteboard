//
//  StringUtility.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/7/22.
//

import Foundation

func localizedString(_ string: String) -> String {
    Bundle.main.localizedString(forKey: string, value: nil, table: nil)
}
