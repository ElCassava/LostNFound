import SwiftUI
import PhotosUI
import CoreML
import Vision

struct AddItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    
    @State private var itemName = ""
    @State private var itemDescription = ""
    @State private var category = "Electronics"
    @State private var locationFound = ""
    @State private var dateFound = Date()
    @State private var selectedImage: UIImage? = nil
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var showSuccessAlert = false
    @State private var imageDescription = ""
    @State private var debugInfo = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Item Details")) {
                    TextField("Item Name", text: $itemName)
                    TextField("Description", text: $itemDescription)
                    TextField("Location Found", text: $locationFound)
                    DatePicker("Date Found", selection: $dateFound, displayedComponents: .date)
                    Picker("Category", selection: $category) {
                        Text("Electronics").tag("Electronics")
                        Text("Clothing").tag("Clothing")
                        Text("Accessories").tag("Accessories")
                    }
                }
                
                Section(header: Text("Add Image")) {
                    PhotosPicker("Select Photo", selection: $selectedPhoto, matching: .images)
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(10)
                    }
                }
                
                if !imageDescription.isEmpty {
                    Section(header: Text("Image Analysis")) {
                        Text(imageDescription)
                    }
                }
            }
            .navigationTitle("Add Item")
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) {
                    isPresented = false
                }
            } message: {
                Text("Item was successfully added!")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addItem()
                    }
                }
            }
            .onChange(of: selectedPhoto) { newPhoto in
                loadSelectedImage()
            }
        }
    }
    
   
    
    func analyzeImage() {
        guard let image = selectedImage else {
            imageDescription = "Could not load image"
            return
        }
        
        debugInfo = "Analyzing image...\nSize: \(image.size.width)x\(image.size.height)"
        
        guard let ciImage = CIImage(image: image) else {
            imageDescription = "Could not create CIImage"
            return
        }
        
        do {
            let model = try VNCoreMLModel(for: YOLOv3().model)
            let request = VNCoreMLRequest(model: model) { request, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.imageDescription = "Error: \(error.localizedDescription)"
                    }
                    return
                }
                
                guard let results = request.results as? [VNRecognizedObjectObservation] else {
                    DispatchQueue.main.async {
                        self.imageDescription = "No results returned"
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    if results.isEmpty {
                        self.imageDescription = "No objects detected."
                    } else {
                        var descriptions: [String] = []
                        var debugText = "Detected objects:\n"
                        
                        
                        if let bestObservation = results.first {
                            let label = bestObservation.labels.first?.identifier ?? "Unknown"
                            let confidence = Int((bestObservation.labels.first?.confidence ?? 0) * 100)
                            
                            debugText += "- \(label) (\(confidence)%)\n"
                            debugText += "  Bounding box: \(bestObservation.boundingBox)\n"
                            
                            descriptions.append("\(label) (\(confidence)%)")
                            
                            
                            self.itemName = label.capitalized
                            self.itemDescription = "An item, \(label), was found in ____ at exactly ___"
                        }
                        
                        self.imageDescription = "Detected: " + descriptions.joined(separator: ", ")
                        self.debugInfo = debugText
                    }
                }
            }
            
            request.imageCropAndScaleOption = .scaleFill
            
            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    DispatchQueue.main.async {
                        self.imageDescription = "Detection failed: \(error.localizedDescription)"
                    }
                }
            }
        } catch {
            imageDescription = "Error loading model: \(error.localizedDescription)"
        }
    }
    
    func loadSelectedImage() {
        guard let selectedPhoto = selectedPhoto else { return }
        Task {
            if let data = try? await selectedPhoto.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                selectedImage = uiImage
                analyzeImage()
            }
        }
    }
    
    func saveImage(_ image: UIImage, withName name: String) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        let fileURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(name)
        
        do {
            try data.write(to: fileURL!)
            print("✅ Image saved successfully: \(fileURL!.absoluteString)")
        } catch {
            print("❌ Error saving image: \(error.localizedDescription)")
        }
    }
    
    func addItem() {
      
        let imageName = "item-\(UUID().uuidString).jpg"


        if let selectedImage = selectedImage {
            saveImage(selectedImage, withName: imageName)
        }


        let newItem = Item(
            id: UUID(),
            dateFound: dateFound,
            itemName: itemName,
            itemDescription: itemDescription,
            isClaimed: false,
            imageName: imageName,
            category: category,
            locationFound: locationFound,
            claimer: nil
        )

        modelContext.insert(newItem)
        showSuccessAlert = true
    }
}
