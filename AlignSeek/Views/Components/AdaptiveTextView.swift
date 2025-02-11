import SwiftUI

struct AdaptiveTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var height: CGFloat
    var placeholder: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: 16)
        textView.backgroundColor = .white
        textView.isScrollEnabled = true
        textView.text = text.isEmpty ? placeholder : text
        textView.textColor = text.isEmpty ? .placeholderText : .black
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.maximumNumberOfLines = 0
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // 确保文本更新
        if uiView.text != text {
            uiView.text = text
            uiView.textColor = text.isEmpty ? .placeholderText : .black
        }
        
        if uiView.window != nil, !context.coordinator.didSetupInitialHeight {
            context.coordinator.didSetupInitialHeight = true
            DispatchQueue.main.async {
                self.height = max(44, uiView.sizeThatFits(CGSize(width: uiView.bounds.width, height: .greatestFiniteMagnitude)).height)
            }
        }
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: AdaptiveTextView
        var didSetupInitialHeight = false
        
        init(_ parent: AdaptiveTextView) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            let size = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude))
            DispatchQueue.main.async {
                self.parent.height = min(max(44, size.height), 120)
            }
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            if textView.textColor == .placeholderText {
                textView.text = ""
                textView.textColor = .black
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            if textView.text.isEmpty {
                textView.text = parent.placeholder
                textView.textColor = .placeholderText
            }
        }
    }
} 
