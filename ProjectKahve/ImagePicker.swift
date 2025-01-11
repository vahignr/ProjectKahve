import SwiftUI
import UIKit

// MARK: - Fortune Image Type
enum FortuneImageType {
    case cup
    case plate
    
    var title: String {
        switch self {
        case .cup:
            return "coffee_cup".localized
        case .plate:
            return "coffee_plate".localized
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    let imageType: FortuneImageType // Added to identify which image is being selected
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = sourceType
        imagePicker.delegate = context.coordinator
        // Add title to clearly indicate which image is being selected
        imagePicker.title = imageType.title
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // Leave this empty
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Fortune Images Model
struct FortuneImages {
    var cupImage: UIImage?
    var plateImage: UIImage?
    
    var isComplete: Bool {
        return cupImage != nil && plateImage != nil
    }
}
