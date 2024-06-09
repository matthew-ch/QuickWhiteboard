//
//  OptionalExtension.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/6/9.
//

import Foundation

extension Optional {
    mutating func take() -> Self {
        let took = self
        self = nil
        return took
    }
}
