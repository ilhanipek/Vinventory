//
//  PhotoModel.swift
//  Vinventory
//
//  Created by ilhan serhan ipek on 27.07.2024.
//

import Foundation

struct Photo: Codable {
    let photoURL: String

    enum CodingKeys: String, CodingKey {
        case photoURL = "photoUrl"
    }
}
