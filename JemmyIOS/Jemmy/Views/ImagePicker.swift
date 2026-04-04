import SwiftUI
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    if let error = error {
                        print("❌ Error loading image: \(error)")
                        return
                    }
                    
                    guard let uiImage = image as? UIImage else { return }
                    
                    // Resize if too large
                    let maxSize: CGFloat = 512
                    let ratio = maxSize / max(uiImage.size.width, uiImage.size.height)
                    
                    let resizedImage: UIImage
                    if ratio < 1 {
                        let newSize = CGSize(
                            width: uiImage.size.width * ratio,
                            height: uiImage.size.height * ratio
                        )
                        
                        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                        uiImage.draw(in: CGRect(origin: .zero, size: newSize))
                        resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? uiImage
                        UIGraphicsEndImageContext()
                    } else {
                        resizedImage = uiImage
                    }
                    
                    DispatchQueue.main.async {
                        self.parent.image = resizedImage
                        print("✅ Image selected and resized")
                    }
                }
            }
        }
    }
}
