import SwiftUI

struct RecordingPageView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isRecording = false
    
    var body: some View {
        ZStack {
            // 背景
            Color.white.ignoresSafeArea()
            
            // 顶部工具栏
            VStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 24) {
                        Button(action: {}) {
                            Image(systemName: "arrow.up.square")
                                .font(.title2)
                                .foregroundColor(.black)
                        }
                        
                        Button(action: {}) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.title2)
                                .foregroundColor(.black)
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                // 中间的波形图
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(#colorLiteral(red: 0.8039215686, green: 0.9176470588, blue: 1, alpha: 1)), Color(#colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1))]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 200, height: 200)
                
                Spacer()
                
                // 底部按钮
                HStack() {
                    Button(action: {
                        isRecording.toggle()
                    }) {
                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(UIColor.systemGray))
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    }
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 24))
                            .foregroundColor(Color(UIColor.systemGray))
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    }
                }.padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
    }
} 
