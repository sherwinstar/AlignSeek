import SwiftUI
import AVFoundation
import Speech

struct RecordingPageView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = RecordingViewModel()
    
    var body: some View {
        ZStack {
            // 背景色
            Color(hex: "F5F5F5").ignoresSafeArea()
            
            VStack {
                // 顶部导航栏
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Spacer()
                
                // 中间区域：显示对话状态
                VStack(spacing: 20) {
                    // 状态文本
                    // 中间的波形图
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: 0x4C8BFF, alpha: 1.0), Color(hex: 0x0245C0, alpha: 1.0)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(viewModel.isProcessing ? 1.1 : 1.0)
                        .animation(
                            viewModel.isProcessing ?
                                Animation.easeInOut(duration: 1.0)
                                    .repeatForever(autoreverses: true)
                                : .default,
                            value: viewModel.isProcessing
                        )

                    
                    Text(viewModel.statusText)
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "1D2129"))
                    
                    // 波形动画
                    WaveformView(
                        samples: viewModel.audioSamples,
                        isRecording: viewModel.isRecording
                    ).opacity(!viewModel.isProcessing && viewModel.isRecording ? 1.0 : 0)
                    .frame(height: 28)
                }
                .padding()
                
                Spacer()
                
                // 底部控制按钮
                Button(action: {
                    viewModel.toggleRecording()
                }) {
                    if viewModel.isRecording {
                        Image("icon_stop")
                            .renderingMode(.template)
                            .resizable()
                            .foregroundColor(Color.red)
                            .frame(width: 64, height: 64)
                    } else {
                        Image("icon_microphone")
                            .frame(width: 64, height: 64)
                    }
                }
                .padding(.bottom, 80)
            }
        }
        .onDisappear() {
            viewModel.stopRecording()
        }
        .navigationBarHidden(true)
    }
}

// ViewModel
class RecordingViewModel: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var audioSamples: [CGFloat] = Array(repeating: 6, count: 40)
    @Published var currentTranscription = ""
    @Published var aiResponse = ""
    @Published var statusText = "Tap button to talk"
    
    private var audioEngine = AVAudioEngine()
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var synthesizer = AVSpeechSynthesizer()
    private var silenceTimer: Timer?
    private var lastAudioTime: Date?
    
    override init() {
        super.init()
        setupAudio()
        synthesizer.delegate = self  // 现在可以安全地设置 delegate
    }
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func setupAudio() {
        // 请求必要的权限
        SFSpeechRecognizer.requestAuthorization { _ in }
        AVAudioSession.sharedInstance().requestRecordPermission { _ in }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func startRecording() {
        guard !isRecording else { return }
        
        // 重置状态
        currentTranscription = ""
        aiResponse = ""
        isRecording = true
        statusText = "AI is listening..."
        
        // 设置音频引擎
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let transcription = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.currentTranscription = transcription
                    print("224:" + self.currentTranscription)
                    self.lastAudioTime = Date()
                }
            }
        }
        
        // 安装音频tap来监听音量
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            self.recognitionRequest?.append(buffer)
            
            // 更新音量波形
            let level = self.calculateDecibels(buffer)
            DispatchQueue.main.async {
                self.updateAudioSamples(with: level)
            }
            
            // 检测静音
            if level < -20 {  // 静音阈值
                self.handleSilence()
            } else {
                self.lastAudioTime = Date()
            }
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    func stopRecording() {
        isRecording = false
        isProcessing = false
        statusText = "Tap button to talk"
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        GoogleMultiService.shared.cancelCurrentTask()
        synthesizer.stopSpeaking(at: .immediate)
        audioSamples = Array(repeating: 6, count: 40)
    }
    
    private func handleSilence() {
        // 如果持续1.5秒没有声音，发送当前转录文本
        if let lastTime = lastAudioTime,
           Date().timeIntervalSince(lastTime) > 1.5,
           !currentTranscription.isEmpty {
            sendTranscriptionToAI()
        }
    }
    
    private func sendTranscriptionToAI() {
        guard !currentTranscription.isEmpty else { return }
        
        let textToSend = currentTranscription
        
        DispatchQueue.main.async { [self] in
            isProcessing = true
            statusText = "AI is thinking..."
            currentTranscription = ""  // 清空当前显示的文本
        }
        
        // 暂停录音以防止录到AI的声音
        audioEngine.pause()
        
        GoogleMultiService.shared.sendMessage(textToSend) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self.aiResponse = response
                    self.speakAIResponse(response)
                case .failure(let error):
                    self.statusText = "发生错误: \(error.localizedDescription)"
                    // 恢复录音
                    try? self.audioEngine.start()
                }
            }
        }
    }
    
    private func speakAIResponse(_ text: String) {
        statusText = "AI is speaking..."
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        
        synthesizer.speak(utterance)
    }
    
    private func calculateDecibels(_ buffer: AVAudioPCMBuffer) -> Float {
        // 计算音量级别的代码...
        return -30  // 示例返回值
    }
    
    private func updateAudioSamples(with level: Float) {
        // 更新波形样本的代码...
        let normalizedLevel = max(0, min(1, (level + 50) / 50))
        let height = CGFloat(normalizedLevel) * 22 + 6  // 6-28范围
        
        audioSamples.removeFirst()
        audioSamples.append(height)
    }
}

// AVSpeechSynthesizerDelegate 实现
extension RecordingViewModel: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.isRecording {
                self.statusText = "AI is listening..."
                self.isProcessing = false
                try? self.audioEngine.start()
            }
        }
    }
}
