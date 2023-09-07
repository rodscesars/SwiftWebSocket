//
//  ContentView.swift
//  SwiftWebSocket
//
//  Created by Rodrigo Mendes on 06/09/23.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = WebSocketViewModel()
    let url = URL(string: "wss://galene.org:8443/ws")!

    var body: some View {
        NavigationStack {
            VStack {
                TextField("Username", text: $viewModel.username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                SecureField("Senha", text: $viewModel.password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("Entrar") {
                    viewModel.webSocketManager?.connect(url: url, id: viewModel.id)
                    viewModel.joinRoom()
                    viewModel.conected = true
                }.padding()
            }
            .padding()
            .navigationDestination(isPresented: $viewModel.conected) {
                ChatView(viewModel: viewModel)
            }
        }

    }
}
