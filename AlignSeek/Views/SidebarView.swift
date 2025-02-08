import SwiftUI

struct SidebarView: View {
    @Binding var isPresented: Bool
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("搜索", text: $searchText)
            }
            .padding(8)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
            .padding()
            
            // AlignSeek 选项
            Button(action: {}) {
                HStack {
                    Image(systemName: "bubble.left.fill")
                        .foregroundColor(.blue)
                    Text("Test")
                        .font(.headline)
                    Spacer()
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
            }
            
            // 探索 AlignSeek 选项
            Button(action: {}) {
                HStack {
                    Image(systemName: "square.grid.2x2")
                        .foregroundColor(.gray)
                    Text("探索 Test")
                        .font(.headline)
                    Spacer()
                }
                .padding()
            }
            
            // 聊天历史分组
            VStack(alignment: .leading, spacing: 0) {
                Text("今天")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                Button(action: {}) {
                    Text("Ddd Clarification")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                
                Text("昨天")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                Button(action: {}) {
                    Text("测试订阅账户设置")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                
                Text("上周")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                Button(action: {}) {
                    Text("开发Python后端帮助")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
            
            Spacer()
            
            // 用户信息
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title)
                Text("用户信息")
                    .font(.headline)
                Spacer()
                Image(systemName: "ellipsis")
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
        }
        .frame(width: UIScreen.main.bounds.width * 0.75)
        .background(Color(UIColor.systemBackground))
    }
} 
