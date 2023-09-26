////
////  VideoCallView.swift
////  SwiftWebSocket
////
////  Created by Rodrigo Mendes on 20/09/23.
////
//
//import SwiftUI
//import WebRTC
//
//struct VideoCallView: View {
//    @ObservedObject var viewModel: ViewModel
//
//    var body: some View {
//        ZStack {
//            VideoView(videoTrack: viewModel.remoteVideoTrack, refresh: Binding {
//                return viewModel.refreshRemoteVideoTrack
//            } set: { newValue  in
//                DispatchQueue.main.async { [self] in
//                    self.viewModel.refreshRemoteVideoTrack = newValue
//                }
//            })
//                .frame(width: 120, height: 160)
//
//
//        }
//        .toolbar {
//            ToolbarItem(placement: .navigationBarTrailing) {
//                HStack {
//                    Button(action: {
//                        viewModel.sendSession()
//                    }) {
//                        Image(systemName: "arrow.right.circle.fill")
//                            .font(.system(size: 10))
//                    }
//
//                    Button(action: {
//                        viewModel.speaker()
//                    }) {
//                        Image(systemName: viewModel.speakerOn ? "speaker.fill" : "speaker.slash.fill")
//                            .font(.system(size: 10))
//                    }
//
//                    Button(action: {
//                        viewModel.muteOn()
//                    }) {
//                        Image(systemName: viewModel.mute ? "mic.slash.fill" : "mic.fill")
//                            .font(.system(size: 10))
//                    }
//                }
//            }
//        }
//    }
//}
//
//struct VideoView: UIViewRepresentable {
//    let videoTrack: RTCVideoTrack?
//    @Binding var refresh: Bool
//
//    func makeUIView(context: Context) -> RTCMTLVideoView {
//        let videoView = RTCMTLVideoView(frame: .zero)
//        videoView.videoContentMode = .scaleAspectFill
//        return videoView
//    }
//
//    func updateUIView(_ uiView: RTCMTLVideoView, context: Context) {
//        if refresh {
//            videoTrack?.add(uiView)
//            refresh = false
//        }
//    }
//}
//
//#Preview {
//    VideoCallView(viewModel: ViewModel())
//}
