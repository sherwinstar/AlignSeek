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
    @State private var selectedImage: UIImage?
    
    var onImageSelected: ((UIImage) -> Void)?
    var onFileSelected: ((URL) -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                checkPhotoLibraryPermission()
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
            ImagePicker(
                sourceType: .photoLibrary,
                selectedImage: $selectedImage,
                onImagePicked: { image in
                    onImageSelected?(image)
                },
                isPresented: $isPresented
            )
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(
                sourceType: .camera,
                selectedImage: $selectedImage,
                onImagePicked: { image in
                    onImageSelected?(image)
                },
                isPresented: $isPresented
            )
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.image, .pdf, .text],
            allowsMultipleSelection: false
        ) { result in
            do {
                if let fileUrl = try result.get().first {
                    onFileSelected?(fileUrl)
                }
            } catch {
                print("Error selecting file: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                self.isPresented = false
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
            showingImagePicker = true  // 只设置显示相册，不关闭菜单
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    if status == .authorized || status == .limited {
                        showingImagePicker = true  // 只设置显示相册，不关闭菜单
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
            showingCamera = true  // 只设置显示相机，不关闭菜单
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showingCamera = true  // 只设置显示相机，不关闭菜单
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
    @Binding var selectedImage: UIImage?
    var onImagePicked: ((UIImage) -> Void)?
    @Binding var isPresented: Bool
    
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
                parent.selectedImage = image
                parent.onImagePicked?(image)
            }
            picker.dismiss(animated: true) {
                self.parent.isPresented = false  // 选择图片后关闭菜单
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true) {
                self.parent.isPresented = false  // 取消选择后关闭菜单
            }
        }
    }
} 
