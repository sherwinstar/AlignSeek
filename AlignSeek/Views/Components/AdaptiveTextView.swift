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
        textView.font = .systemFont(ofSize: 15)
        textView.backgroundColor = .clear
        textView.isScrollEnabled = true
        textView.text = text
        textView.textColor = .black
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 8, right: 0)
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
                self.height = max(52, uiView.sizeThatFits(CGSize(width: uiView.bounds.width, height: .greatestFiniteMagnitude)).height)
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
            parent.height = max(52, textView.sizeThatFits(CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude)).height)
        }
    }
}

// 创建一个包装视图来处理 placeholder
struct AdaptiveTextViewWithPlaceholder: View {
    @Binding var text: String
    @Binding var height: CGFloat
    var placeholder: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack(alignment: .leading) {
            // 占位符文本
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(placeholder)
                    .foregroundColor(Color(hex: 0x828282, alpha: 1))
                    .font(.system(size: 15))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)
            }
            
            AdaptiveTextView(text: $text, height: $height)
                .background(Color.clear)

//            // 实际的文本输入框
//            UITextViewWrapper(text: $text, calculatedHeight: $height)
//                .frame(minHeight: 52, maxHeight: 120)
//                .padding(.horizontal, 8)
        }
    }
}

struct UITextViewWrapper: UIViewRepresentable {
    @Binding var text: String
    @Binding var calculatedHeight: CGFloat
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, height: $calculatedHeight)
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: 16)
        textView.backgroundColor = .clear
        textView.isScrollEnabled = true
        textView.text = text
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        // 确保文本视图的大小更新
        UITextViewWrapper.recalculateHeight(view: uiView, result: $calculatedHeight)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var text: Binding<String>
        var height: Binding<CGFloat>
        
        init(text: Binding<String>, height: Binding<CGFloat>) {
            self.text = text
            self.height = height
        }
        
        func textViewDidChange(_ textView: UITextView) {
            text.wrappedValue = textView.text
            height.wrappedValue = max(52, textView.sizeThatFits(CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude)).height)
        }
    }
    
    static func recalculateHeight(view: UITextView, result: Binding<CGFloat>) {
        let size = view.sizeThatFits(CGSize(width: view.bounds.width, height: .greatestFiniteMagnitude))
        result.wrappedValue = max(52, size.height)
    }
}

