//
//  ChatView.swift
//  SwiftWebSocket
//
//  Created by Rodrigo Mendes on 06/09/23.
//

import SwiftUI

struct ChatView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: WebSocketViewModel
    @State var message: String = ""

    var body: some View {
        VStack {
            List {
                ForEach(viewModel.messages, id: \.self) { message in
                    HStack {
                        if message.username == viewModel.username {
                            Text("Me:")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        } else {
                            Text("\(message.username):")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }

                        Text(message.value)
                    }
                }
            }

            HStack {
                TextField("Enter a message", text: $message)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button {
                    viewModel.sendMessage(message: message)
                    message = ""
                } label: {
                    Text("Send")
                }.padding()
            }.padding()
        }
        .navigationBarBackButtonHidden()
        .navigationBarTitle("Chat \(viewModel.users.count > 0 ? "(\(viewModel.users.count) connected)" : "")")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    ParticipantsListView(users: viewModel.users)
                } label: {
                    Image(systemName: "person")
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    viewModel.webSocketManager?.disconnect()
                    viewModel.messages = []
                    viewModel.users = []
                    dismiss()
                } label: {
                    Image(systemName: "phone.down")
                }
            }
        }
    }
}
