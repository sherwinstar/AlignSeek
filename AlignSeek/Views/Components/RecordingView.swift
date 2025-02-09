import SwiftUI
import AVFoundation

struct RecordingView: View {
    @Binding var isRecording: Bool
    @State private var recordingTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var audioRecorder: AVAudioRecorder?
    
    var body: some View {
        HStack {
            // 取消按钮
            Button(action: {
                stopRecording(cancelled: true)
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 24))
                    .foregroundColor(.black)
                    .frame(width: 36, height: 36)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // 录音波形和时间
            VStack(spacing: 4) {
                // 录音波形图
                Image(systemName: "waveform")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                    .opacity(isRecording ? 1 : 0.5)
                
                // 录音时间
                Text(timeString(from: recordingTime))
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // 完成按钮
            Button(action: {
                stopRecording(cancelled: false)
            }) {
                Image(systemName: "checkmark")
                    .font(.system(size: 24))
                    .foregroundColor(.black)
                    .frame(width: 36, height: 36)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 60)
        .background(Color.white)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 20,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 20
            )
        )
        .overlay(
            GeometryReader { geometry in
                Path { path in
                    let w = geometry.size.width
                    let radius: CGFloat = 20
                    
                    // 只绘制上半部分
                    path.move(to: CGPoint(x: 0, y: radius))  // 从左边开始
                    path.addArc(center: CGPoint(x: radius, y: radius),
                               radius: radius,
                               startAngle: .degrees(180),
                               endAngle: .degrees(270),
                               clockwise: false)  // 左上角圆弧
                    path.addLine(to: CGPoint(x: w - radius, y: 0))  // 上边线
                    path.addArc(center: CGPoint(x: w - radius, y: radius),
                               radius: radius,
                               startAngle: .degrees(270),
                               endAngle: .degrees(0),
                               clockwise: false)  // 右上角圆弧
                }
                .stroke(Color(UIColor.systemGray5), lineWidth: 0.5)
            }
        )
        .onAppear {
            startRecording()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func startRecording() {
        // 请求麦克风权限
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                // 设置录音会话
                try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
                try? AVAudioSession.sharedInstance().setActive(true)
                
                // 设置录音文件路径
                let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
                
                // 录音设置
                let settings = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 44100,
                    AVNumberOfChannelsKey: 2,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ]
                
                // 创建录音器
                do {
                    audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
                    audioRecorder?.record()
                    isRecording = true
                    
                    // 开始计时
                    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                        recordingTime += 1
                    }
                } catch {
                    print("录音失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func stopRecording(cancelled: Bool) {
        timer?.invalidate()
        timer = nil
        
        audioRecorder?.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
        
        if cancelled {
            // 如果取消录音，删除录音文件
            if let url = audioRecorder?.url {
                try? FileManager.default.removeItem(at: url)
            }
        } else {
            // 如果完成录音，处理录音文件
            if let url = audioRecorder?.url {
                print("录音文件保存在: \(url)")
                // TODO: 处理录音文件，例如上传或播放
            }
        }
        
        isRecording = false
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
} 