//
//  ChatView.swift
//  SwiftWebSocket
//
//  Created by Rodrigo Mendes on 06/09/23.
//

import SwiftUI

struct ChatView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ViewModel
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
                HStack {
                    Button {
                        viewModel.webSocketManager?.disconnect()
                        viewModel.messages = []
                        viewModel.users = []
                        dismiss()
                    } label: {
                        Image(systemName: "phone.down")
                    }

                    NavigationLink {
                        ParticipantsListView(users: viewModel.users)
                    } label: {
                        Image(systemName: "person")
                    }

                    NavigationLink {
//                        VideoViewControllerWrapper(webRTCClient: viewModel.webRTC)
                        VideoCallView(viewModel: viewModel)
                    } label: {
                        Image(systemName: "video.fill")
                    }
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    Button(action: {
                        viewModel.sendSession()
                    }) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 15))
                    }

                    Button(action: {
                        viewModel.speaker()
                    }) {
                        Image(systemName: viewModel.speakerOn ? "speaker.fill" : "speaker.slash.fill")
                            .font(.system(size: 15))
                    }

                    Button(action: {
                        viewModel.muteOn()
                    }) {
                        Image(systemName: viewModel.mute ? "mic.slash.fill" : "mic.fill")
                            .font(.system(size: 15))
                    }
                }
            }
        }
    }
}
