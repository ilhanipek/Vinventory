//
//  CurrenUserModel.swift
//  Vinventory
//
//  Created by ilhan serhan ipek on 23.07.2024.
//

import Foundation

struct CurrentUserModel: Decodable {
    let displayName, givenName, mail: String
    let surname, userPrincipalName, id: String
}
