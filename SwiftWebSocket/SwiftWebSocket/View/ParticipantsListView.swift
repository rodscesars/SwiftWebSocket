//
//  ParticipantsListView.swift
//  SwiftWebSocket
//
//  Created by Rodrigo Mendes on 06/09/23.
//

import SwiftUI

struct ParticipantsListView: View {
    var users: [User]

    var body: some View {
        VStack {
            List {
                ForEach(users, id: \.self) { user in
                    Text(user.username)
                }
            }
        }
    }
}
