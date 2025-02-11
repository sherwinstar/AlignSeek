import SwiftUI

struct AdaptiveTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var height: CGFloat
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: 16)
        textView.backgroundColor = .clear
        textView.isScrollEnabled = true
        textView.text = text
        textView.textColor = .black
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
            parent.height = max(44, textView.sizeThatFits(CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude)).height)
        }
    }
}

// 创建一个包装视图来处理 placeholder
struct AdaptiveTextViewWithPlaceholder: View {
    @Binding var text: String
    @Binding var height: CGFloat
    var placeholder: String
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(Color(.placeholderText))
                    .padding(.horizontal, 2)
                    .padding(.top, 7)
                    .zIndex(1)
            }
            AdaptiveTextView(text: $text, height: $height)
                .background(Color.clear)
        }
    }
}

