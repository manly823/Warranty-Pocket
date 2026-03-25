import SwiftUI
import Vision

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

enum OCR {
    static func recognizeText(from image: UIImage, completion: @escaping (String) -> Void) {
        guard let cgImage = image.cgImage else { completion(""); return }
        let request = VNRecognizeTextRequest { request, _ in
            let results = (request.results as? [VNRecognizedTextObservation]) ?? []
            let text = results.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
            DispatchQueue.main.async { completion(text) }
        }
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US", "en-GB"]
        DispatchQueue.global(qos: .userInitiated).async {
            try? VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
        }
    }

    static func extractDate(from text: String) -> Date? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        let matches = detector?.matches(in: text, range: NSRange(text.startIndex..., in: text)) ?? []
        return matches.first?.date
    }

    static func extractPrice(from text: String) -> Double? {
        let patterns = [
            "total[:\\s]*\\$?\\s*([\\d,]+\\.\\d{2})",
            "\\$\\s*([\\d,]+\\.\\d{2})",
            "([\\d,]+\\.\\d{2})\\s*\\$"
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
                let rangeIdx = match.numberOfRanges > 1 ? 1 : 0
                if let range = Range(match.range(at: rangeIdx), in: text) {
                    let str = text[range].replacingOccurrences(of: ",", with: "")
                    if let val = Double(str) { return val }
                }
            }
        }
        return nil
    }

    static func extractStoreName(from text: String) -> String? {
        let lines = text.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard let first = lines.first else { return nil }
        let trimmed = first.trimmingCharacters(in: .whitespaces)
        return trimmed.count > 2 && trimmed.count < 60 ? trimmed : nil
    }
}
