//
//  String.swift
//  Vinventory
//
//  Created by ilhan serhan ipek on 31.07.2024.
//

import Foundation

extension String {
    func capitalizedWords() -> String {
        return self.split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
    }
}
