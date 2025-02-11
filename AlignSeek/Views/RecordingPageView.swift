import SwiftUI
import AVFoundation
import Speech

struct RecordingPageView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isRecording = false
    @State private var recordingTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var audioRecorder: AVAudioRecorder?
    @State private var synthesizer = AVSpeechSynthesizer()
    @State private var isProcessing = false
    @State private var rotationDegree: Double = 0
    @State private var synthesizerDelegate: SpeechSynthesizerDelegate?
    
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
                    
                    // HStack(spacing: 24) {
                    //     Button(action: {}) {
                    //         Image(systemName: "arrow.up.square")
                    //             .font(.title2)
                    //             .foregroundColor(.black)
                    //     }
                        
                    //     Button(action: {}) {
                    //         Image(systemName: "slider.horizontal.3")
                    //             .font(.title2)
                    //             .foregroundColor(.black)
                    //     }
                    // }
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
                    .rotationEffect(.degrees(rotationDegree))
                    .overlay(
                        Group {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                            }
                        }
                    )
                    .onTapGesture {
                        if isProcessing {
                            stopProcessing()
                        }
                    }
                
                Spacer()
                
                // 底部按钮
                HStack() {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(UIColor.systemGray))
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if !isRecording {
                                        startRecording()
                                    }
                                }
                                .onEnded { _ in
                                    if isRecording {
                                        stopRecording()
                                    }
                                }
                        )
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
        .onDisappear {
            cleanUp()
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func startRecording() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
                    try AVAudioSession.sharedInstance().setActive(true)
                    
                    let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
                    let settings = [
                        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                        AVSampleRateKey: 44100,
                        AVNumberOfChannelsKey: 2,
                        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                    ]
                    
                    audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
                    audioRecorder?.record()
                    
                    DispatchQueue.main.async {
                        isRecording = true
                        recordingTime = 0
                        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                            recordingTime += 1
                        }
                    }
                } catch {
                    print("录音失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func stopRecording() {
        timer?.invalidate()
        timer = nil
        
        audioRecorder?.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
        
        if let url = audioRecorder?.url {
            transcribeAudio(url: url)
        }
        
        isRecording = false
    }
    
    private func startProcessingAnimation() {
        withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
            rotationDegree = 360
        }
    }
    
    private func stopProcessingAnimation() {
        withAnimation {
            rotationDegree = 0
        }
    }
    
    private func stopProcessing() {
        synthesizer.stopSpeaking(at: .immediate)  // 立即停止语音播放
        isProcessing = false
        stopProcessingAnimation()
    }
    
    private func transcribeAudio(url: URL) {
        isProcessing = true
        startProcessingAnimation()
        
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
                        // 调用 API 获取响应
                        APIService2.shared.sendMessage(transcription) { result in
                            DispatchQueue.main.async {
//                                isProcessing = false
                                stopProcessingAnimation()
                                
                                switch result {
                                case .success(let response):
                                    speakText(response)
                                case .failure(let error):
                                    print("API Error: \(error.localizedDescription)")
                                }
                            }
                            
                            // 删除录音文件
                            try? FileManager.default.removeItem(at: url)
                        }
                    }
                }
            }
        }
    }
    
    private func speakText(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        synthesizerDelegate = SpeechSynthesizerDelegate(onFinish: {
            DispatchQueue.main.async {
                isProcessing = false
                stopProcessingAnimation()
            }
        })
        synthesizer.delegate = synthesizerDelegate
        
        synthesizer.speak(utterance)
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func cleanUp() {
        // 停止录音
        if isRecording {
            timer?.invalidate()
            timer = nil
            audioRecorder?.stop()
            try? AVAudioSession.sharedInstance().setActive(false)
            isRecording = false
        }
        
        // 停止语音播放和动画
        if isProcessing {
            synthesizer.stopSpeaking(at: .immediate)
            isProcessing = false
            stopProcessingAnimation()
        }
    }
}

class SpeechSynthesizerDelegate: NSObject, AVSpeechSynthesizerDelegate {
    let onFinish: () -> Void
    
    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinish()
    }
}
