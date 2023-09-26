//
//  Models.swift
//  SwiftWebSocket
//
//  Created by Rodrigo Mendes on 06/09/23.
//

import Foundation

struct ChatMessage: Decodable, Hashable {
    let username: String //email
    let value: String //message
    let time: String //date
}

struct User: Decodable, Hashable {
    let id: String
    let username: String
}
