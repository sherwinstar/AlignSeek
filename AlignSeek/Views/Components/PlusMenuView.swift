import SwiftUI
import Photos
import AVFoundation

struct PlusMenuView: View {
    @Binding var isPresented: Bool
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingFileImporter = false
    @State private var showingPermissionAlert = false
    @State private var permissionAlertType = ""
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                checkPhotoLibraryPermission()
                isPresented = false  // 关闭菜单
            }) {
                HStack {
                    Text("附加照片")
                        .font(.system(size: 17))
                    Spacer()
                    Image(systemName: "photo")
                }
                .foregroundColor(.black)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            
            Divider()
            
            Button(action: {
                checkCameraPermission()
                isPresented = false  // 关闭菜单
            }) {
                HStack {
                    Text("拍照")
                        .font(.system(size: 17))
                    Spacer()
                    Image(systemName: "camera")
                }
                .foregroundColor(.black)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            
            Divider()
            
            Button(action: {
                showingFileImporter = true
                isPresented = false  // 关闭菜单
            }) {
                HStack {
                    Text("附加文件")
                        .font(.system(size: 17))
                    Spacer()
                    Image(systemName: "folder")
                }
                .foregroundColor(.black)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
        }
        .frame(width: UIScreen.main.bounds.width * 0.4)
        .background(.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 0)
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(sourceType: .camera)
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.image, .pdf, .text],
            allowsMultipleSelection: false
        ) { result in
            do {
                let fileUrl = try result.get().first
                // 处理选中的文件
                print("Selected file: \(fileUrl?.lastPathComponent ?? "")")
            } catch {
                print("Error selecting file: \(error.localizedDescription)")
            }
        }
        .alert(permissionAlertType, isPresented: $showingPermissionAlert) {
            Button("设置", role: .none) {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text(getPermissionMessage())
        }
    }
    
    private func getPermissionMessage() -> String {
        switch permissionAlertType {
        case "相机权限":
            return "需要相机权限才能拍照，请在设置中开启。"
        case "相册权限":
            return "需要相册权限才能选择照片，请在设置中开启。"
        default:
            return ""
        }
    }
    
    private func checkPhotoLibraryPermission() {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized, .limited:
            showingImagePicker = true
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    if status == .authorized || status == .limited {
                        showingImagePicker = true
                    }
                }
            }
        default:
            permissionAlertType = "相册权限"
            showingPermissionAlert = true
        }
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showingCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showingCamera = true
                    }
                }
            }
        default:
            permissionAlertType = "相机权限"
            showingPermissionAlert = true
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                // 处理选中的图片
                print("Selected image size: \(image.size)")
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
} 