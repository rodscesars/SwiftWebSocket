//
//  ContentView.swift
//  SwiftWebSocket
//
//  Created by Rodrigo Mendes on 06/09/23.
//

import SwiftUI
import AVFoundation
import WebRTC

struct ContentView: View {
    @ObservedObject var viewModel = ViewModel()
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

                Button("Permissão de câmera") {
                    requestCameraPermission()
                }.disabled(viewModel.cameraPermissionGranted)

                Button("Permissão de microfone") {
                    requestMicrophonePermission()
                }.disabled(viewModel.microphonePermissionGranted)
            }
            .onAppear {
                requestCameraPermission()
                requestMicrophonePermission()
            }
            .padding()
            .navigationDestination(isPresented: $viewModel.conected) {
                ChatView(viewModel: viewModel)
            }
        }

    }

    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                viewModel.cameraPermissionGranted = granted
            }
        }
    }

    private func requestMicrophonePermission() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async {
                viewModel.microphonePermissionGranted = granted
            }
        }
    }
}
