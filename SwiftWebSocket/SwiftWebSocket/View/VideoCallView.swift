//
//  VideoCallView.swift
//  SwiftWebSocket
//
//  Created by Rodrigo Mendes on 20/09/23.
//

import SwiftUI
import WebRTC

struct VideoCallView: View {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        VStack(spacing: 10) {
            VideoView(videoTrack: viewModel.localVideoTrack).frame(width: 160, height: 160)

            ForEach(viewModel.remoteVideoTracks, id: \.self) { value in
                VideoView(videoTrack: value).frame(width: 160, height: 160)
            }

        }.onAppear {
            viewModel.webRTC?.startCaptureLocalVideo()
        }.toolbar {
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

                    Button {
                        viewModel.hideOn()
                    } label: {
                        Image(systemName: viewModel.hide ? "video.slash.fill" : "video.fill").font(.system(size: 15))
                    }

                }
            }
        }
    }
}

struct VideoView: UIViewRepresentable {
    let videoTrack: RTCVideoTrack?

    func makeUIView(context: Context) -> RTCMTLVideoView {
        let videoView = RTCMTLVideoView(frame: .zero)
        videoView.videoContentMode = .scaleAspectFill
        return videoView
    }

    func updateUIView(_ uiView: RTCMTLVideoView, context: Context) {
        if ((videoTrack?.isEnabled) != nil) {
            videoTrack?.add(uiView)
        }
    }
}


#Preview {
    VideoCallView(viewModel: ViewModel())
}
