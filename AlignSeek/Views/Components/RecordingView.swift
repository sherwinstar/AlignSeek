import SwiftUI
import AVFoundation
import Speech

struct WaveformView: View {
    let samples: [CGFloat] // 声音样本数据
    let isRecording: Bool
    
    var body: some View {
        HStack(spacing: 2) {  // 波形条之间间距2dp
            ForEach(0..<40, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)  // 1dp的圆角
                    .fill(isRecording ? Color(hex: 0x206EFF) : Color(hex: 0x828282))
                    .frame(width: 2, height: max(6, samples[safe: index] ?? 6))  // 最小高度6dp，最大28dp
            }
        }
    }
}

struct RecordingView: View {
    @Binding var isRecording: Bool
    @State private var recordingTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var audioRecorder: AVAudioRecorder?
    @State private var samples: [CGFloat] = Array(repeating: 6, count: 40)
    @State private var meterTimer: Timer?
    var onTranscriptionComplete: ((String) -> Void)?
    
    var body: some View {
        HStack {
            // 取消按钮
            Button(action: {
                stopRecording(cancelled: true)
            }) {
                Image("icon_close_mini")
                    .frame(width: 29, height: 29)
            }
            .padding(.leading, 12)
            
            Spacer()
            
            // 波形和时间
            HStack(spacing: 8) {
                // 自定义波形视图
                WaveformView(samples: samples, isRecording: isRecording)
                    .frame(height: 24)  // 最大高度28dp
                
                // 录音时间
                Text(String(format: "%02d:%02d", Int(recordingTime) / 60, Int(recordingTime) % 60))
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: 0x1D2129))
                    .monospacedDigit()
            }
            
            Spacer()
            
            // 完成按钮
            Button(action: {
                stopRecording(cancelled: false)
            }) {
                Image("icon_send_audio")
                    .frame(width: 29, height: 29)
            }
            .padding(.trailing, 12)
        }
        .frame(height: 52)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "E5E6EB"), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .shadow(color: Color(hex: 0x191D28, alpha: 0.06), radius: 5, x: 0, y: 6)
        .onAppear {
            startRecording()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
            meterTimer?.invalidate()
            meterTimer = nil
        }
    }
    
    private func startRecording() {
        // 设置录音会话
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playAndRecord, mode: .default)
        try? audioSession.setActive(true)
        
        // 设置录音文件路径（临时文件）
        let audioFilename = FileManager.default.temporaryDirectory.appendingPathComponent("recording.wav")
        
        // 录音设置
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        // 创建录音器
        audioRecorder = try? AVAudioRecorder(url: audioFilename, settings: settings)
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.record()
        
        // 开始计时
        startTimer()
        
        // 开始音量监测
        startMeterTimer()
    }
    
    private func startTimer() {
        // 开始计时
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            recordingTime += 1
        }
    }
    
    private func startMeterTimer() {
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            audioRecorder?.updateMeters()
            let power = audioRecorder?.averagePower(forChannel: 0) ?? -160
            
            // 将 power 转换为 0-1 范围
            let normalizedPower = (power + 160) / 160
            
            // 计算高度：6dp 到 24dp
            let height = 6 + (normalizedPower * 18)
            
            // 向左移动现有样本
            var newSamples = self.samples
            newSamples.removeFirst()
            newSamples.append(CGFloat(height))
            
            self.samples = newSamples
        }
    }
    
    private func stopRecording(cancelled: Bool) {
        // 停止计时器
        timer?.invalidate()
        timer = nil
        meterTimer?.invalidate()
        meterTimer = nil
        
        // 停止录音
        audioRecorder?.stop()
        
        if cancelled {
            // 如果取消录音，删除录音文件
            if let url = audioRecorder?.url {
                try? FileManager.default.removeItem(at: url)
            }
        } else {
            // 如果完成录音，进行语音识别
            if let url = audioRecorder?.url {
                transcribeAudio(url: url)
            }
        }
        
        // 清理录音器
        audioRecorder = nil
        try? AVAudioSession.sharedInstance().setActive(false)
        
        isRecording = false
    }
    
    private func transcribeAudio(url: URL) {
        // 请求语音识别权限
        SFSpeechRecognizer.requestAuthorization { authStatus in
            if authStatus == .authorized {
                let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
                let request = SFSpeechURLRecognitionRequest(url: url)
                
                recognizer?.recognitionTask(with: request) { result, error in
                    if let error = error {
                        print("Recognition error: \(error)")
                        return
                    }
                    
                    if let result = result {
                        let transcription = result.bestTranscription.formattedString
                        print("111:" + transcription)
                        DispatchQueue.main.async {
                            // 调用回调更新输入框
                            onTranscriptionComplete?(transcription)
                            // 删除录音文件
                            try? FileManager.default.removeItem(at: url)
                        }
                    }
                }
            }
        }
    }
}

// 安全数组访问
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
} 
