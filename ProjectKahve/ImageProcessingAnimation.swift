import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import Vision

struct ImageProcessingView: View {
    let image: UIImage
    @State private var processedImage: UIImage?
    @State private var effectTimer: Timer?
    @State private var lastEffectName: String?
    @State private var detectedFeatures: [Path] = []
    
    private let context = CIContext()
    private let effectOptions: [String] = [
        "SmartEdgeDetection",
        "ContourDetection",
        "FeaturePoints",
        "AdaptiveBinarization",
        "ColoredContours",
        "CircleDetection",
        "EnhancedStructure",
        "AdvancedSobel",
        "ShapeDetection",
        "ObjectBoundaries"
    ]
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(UIColor.systemBackground).opacity(0.9),
                            Color(UIColor.systemBackground)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 220, height: 220)
                .shadow(color: Color.primary.opacity(0.2), radius: 10, x: 0, y: 5)
            
            if let processedImage = processedImage {
                Image(uiImage: processedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.8), value: processedImage)
                    .overlay(
                        ForEach(0..<detectedFeatures.count, id: \.self) { index in
                            detectedFeatures[index]
                                .stroke(Color.green, lineWidth: 1)
                        }
                    )
                    .onAppear {
                        startEffectAnimation()
                    }
                    .onDisappear {
                        stopEffectAnimation()
                    }
            } else {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .onAppear {
                        startEffectAnimation()
                    }
                    .onDisappear {
                        stopEffectAnimation()
                    }
            }
        }
    }
    
    func startEffectAnimation() {
        applyUniqueRandomEffect()
        effectTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            withAnimation {
                applyUniqueRandomEffect()
            }
        }
    }
    
    func stopEffectAnimation() {
        effectTimer?.invalidate()
        effectTimer = nil
    }
    
    func applyUniqueRandomEffect() {
        guard let ciImage = CIImage(image: image) else { return }
        
        var filterName: String
        repeat {
            filterName = effectOptions.randomElement()!
        } while filterName == lastEffectName
        
        lastEffectName = filterName
        
        switch filterName {
        case "SmartEdgeDetection":
            applySmartEdgeDetection(ciImage: ciImage)
        case "ContourDetection":
            applyContourDetection(ciImage: ciImage)
        case "FeaturePoints":
            detectFeaturePoints(image: image)
        case "AdaptiveBinarization":
            applyAdaptiveBinarization(ciImage: ciImage)
        case "ColoredContours":
            applyColoredContours(ciImage: ciImage)
        case "CircleDetection":
            detectCircles(image: image)
        case "EnhancedStructure":
            applyEnhancedStructure(ciImage: ciImage)
        case "AdvancedSobel":
            applyAdvancedSobel(ciImage: ciImage)
        case "ShapeDetection":
            detectShapes(image: image)
        case "ObjectBoundaries":
            detectObjectBoundaries(image: image)
        default:
            applySmartEdgeDetection(ciImage: ciImage)
        }
    }

    private func applySmartEdgeDetection(ciImage: CIImage) {
            let edgeWork = CIFilter.edgeWork()
            edgeWork.inputImage = ciImage
            edgeWork.radius = 3
            
            let edges = CIFilter.edges()
            edges.inputImage = edgeWork.outputImage
            edges.intensity = 2.0
            
            if let outputImage = edges.outputImage?.applyingFilter("CIColorInvert") {
                renderFilteredImage(outputImage)
            }
        }
        
        private func applyContourDetection(ciImage: CIImage) {
            let filter1 = CIFilter.colorControls()
            filter1.inputImage = ciImage
            filter1.contrast = 2.5
            filter1.brightness = 0.0
            filter1.saturation = 0.0
            
            let filter2 = CIFilter.edges()
            filter2.inputImage = filter1.outputImage
            filter2.intensity = 3.0
            
            if let outputImage = filter2.outputImage {
                renderFilteredImage(outputImage)
            }
        }
        
        private func detectFeaturePoints(image: UIImage) {
            guard let cgImage = image.cgImage else { return }
            
            let request = VNDetectRectanglesRequest { request, error in
                guard let results = request.results as? [VNRectangleObservation] else { return }
                
                self.detectedFeatures = results.map { observation in
                    Path { path in
                        path.move(to: CGPoint(x: observation.topLeft.x * 200, y: observation.topLeft.y * 200))
                        path.addLine(to: CGPoint(x: observation.topRight.x * 200, y: observation.topRight.y * 200))
                        path.addLine(to: CGPoint(x: observation.bottomRight.x * 200, y: observation.bottomRight.y * 200))
                        path.addLine(to: CGPoint(x: observation.bottomLeft.x * 200, y: observation.bottomLeft.y * 200))
                        path.closeSubpath()
                    }
                }
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
            
            if let ciImage = CIImage(image: image) {
                let filter = CIFilter.photoEffectNoir()
                filter.inputImage = ciImage
                if let outputImage = filter.outputImage {
                    renderFilteredImage(outputImage)
                }
            }
        }
        
        private func applyAdaptiveBinarization(ciImage: CIImage) {
            let filter1 = CIFilter.colorControls()
            filter1.inputImage = ciImage
            filter1.contrast = 2.0
            filter1.brightness = 0.0
            filter1.saturation = 0.0
            
            let filter2 = CIFilter.colorThreshold()
            filter2.inputImage = filter1.outputImage
            
            if let outputImage = filter2.outputImage {
                renderFilteredImage(outputImage)
            }
        }
        
        private func applyColoredContours(ciImage: CIImage) {
            let edges = CIFilter.edges()
            edges.inputImage = ciImage
            edges.intensity = 2.0
            
            let colorControls = CIFilter.colorControls()
            colorControls.inputImage = edges.outputImage
            colorControls.saturation = 2.0
            colorControls.contrast = 2.0
            
            if let outputImage = colorControls.outputImage {
                renderFilteredImage(outputImage)
            }
        }
        
        private func detectCircles(image: UIImage) {
            guard let cgImage = image.cgImage else { return }
            
            let request = VNDetectContoursRequest { request, error in
                guard let results = request.results as? [VNContoursObservation] else { return }
                
                self.detectedFeatures = results.map { observation in
                    Path { path in
                        observation.normalizedPath.applyWithBlock { element in
                            let points = element.pointee.points
                            switch element.pointee.type {
                            case .moveToPoint:
                                path.move(to: CGPoint(x: points[0].x * 200, y: points[0].y * 200))
                            case .addLineToPoint:
                                path.addLine(to: CGPoint(x: points[0].x * 200, y: points[0].y * 200))
                            case .addQuadCurveToPoint:
                                path.addQuadCurve(
                                    to: CGPoint(x: points[1].x * 200, y: points[1].y * 200),
                                    control: CGPoint(x: points[0].x * 200, y: points[0].y * 200)
                                )
                            case .addCurveToPoint:
                                path.addCurve(
                                    to: CGPoint(x: points[2].x * 200, y: points[2].y * 200),
                                    control1: CGPoint(x: points[0].x * 200, y: points[0].y * 200),
                                    control2: CGPoint(x: points[1].x * 200, y: points[1].y * 200)
                                )
                            case .closeSubpath:
                                path.closeSubpath()
                            @unknown default:
                                break
                            }
                        }
                    }
                }
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
            
            if let ciImage = CIImage(image: image) {
                let filter = CIFilter.edges()
                filter.inputImage = ciImage
                filter.intensity = 1.5
                if let outputImage = filter.outputImage {
                    renderFilteredImage(outputImage)
                }
            }
        }
        
        private func applyEnhancedStructure(ciImage: CIImage) {
            let filter1 = CIFilter.sharpenLuminance()
            filter1.inputImage = ciImage
            filter1.sharpness = 2.0
            
            let filter2 = CIFilter.edges()
            filter2.inputImage = filter1.outputImage
            filter2.intensity = 1.5
            
            if let outputImage = filter2.outputImage {
                renderFilteredImage(outputImage)
            }
        }
        
        private func applyAdvancedSobel(ciImage: CIImage) {
            let filter1 = CIFilter.edges()
            filter1.inputImage = ciImage
            filter1.intensity = 2.5
            
            let filter2 = CIFilter.colorControls()
            filter2.inputImage = filter1.outputImage
            filter2.contrast = 1.5
            filter2.brightness = 0.0
            filter2.saturation = 0.0
            
            if let outputImage = filter2.outputImage {
                renderFilteredImage(outputImage)
            }
        }
        
        private func detectShapes(image: UIImage) {
            guard let cgImage = image.cgImage else { return }
            
            let request = VNDetectRectanglesRequest { request, error in
                guard let results = request.results as? [VNRectangleObservation] else { return }
                
                self.detectedFeatures = results.map { observation in
                    Path { path in
                        let topLeft = CGPoint(x: observation.topLeft.x * 200, y: observation.topLeft.y * 200)
                        let topRight = CGPoint(x: observation.topRight.x * 200, y: observation.topRight.y * 200)
                        let bottomRight = CGPoint(x: observation.bottomRight.x * 200, y: observation.bottomRight.y * 200)
                        let bottomLeft = CGPoint(x: observation.bottomLeft.x * 200, y: observation.bottomLeft.y * 200)
                        
                        path.move(to: topLeft)
                        path.addLine(to: topRight)
                        path.addLine(to: bottomRight)
                        path.addLine(to: bottomLeft)
                        path.closeSubpath()
                    }
                }
            }
            
            request.minimumAspectRatio = 0.1
            request.maximumAspectRatio = 0.9
            request.minimumSize = 0.1
            request.maximumObservations = 3
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
            
            if let ciImage = CIImage(image: image) {
                let filter = CIFilter.photoEffectNoir()
                filter.inputImage = ciImage
                if let outputImage = filter.outputImage {
                    renderFilteredImage(outputImage)
                }
            }
        }
        
        private func detectObjectBoundaries(image: UIImage) {
            guard let cgImage = image.cgImage else { return }
            
            let request = VNDetectContoursRequest { request, error in
                guard let results = request.results as? [VNContoursObservation] else { return }
                
                self.detectedFeatures = results.map { observation in
                    Path { path in
                        observation.normalizedPath.applyWithBlock { element in
                            let points = element.pointee.points
                            switch element.pointee.type {
                            case .moveToPoint:
                                path.move(to: CGPoint(x: points[0].x * 200, y: points[0].y * 200))
                            case .addLineToPoint:
                                path.addLine(to: CGPoint(x: points[0].x * 200, y: points[0].y * 200))
                            case .addQuadCurveToPoint:
                                path.addQuadCurve(
                                    to: CGPoint(x: points[1].x * 200, y: points[1].y * 200),
                                    control: CGPoint(x: points[0].x * 200, y: points[0].y * 200)
                                )
                            case .addCurveToPoint:
                                path.addCurve(
                                    to: CGPoint(x: points[2].x * 200, y: points[2].y * 200),
                                    control1: CGPoint(x: points[0].x * 200, y: points[0].y * 200),
                                    control2: CGPoint(x: points[1].x * 200, y: points[1].y * 200)
                                )
                            case .closeSubpath:
                                path.closeSubpath()
                            @unknown default:
                                break
                            }
                        }
                    }
                }
            }
            
            request.contrastAdjustment = 2.0
            request.detectsDarkOnLight = true
            request.maximumImageDimension = 512
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
            
            if let ciImage = CIImage(image: image) {
                let edges = CIFilter.edges()
                edges.inputImage = ciImage
                edges.intensity = 1.0
                
                let colorControls = CIFilter.colorControls()
                colorControls.inputImage = edges.outputImage
                colorControls.saturation = 1.5
                colorControls.contrast = 1.2
                
                if let outputImage = colorControls.outputImage {
                    renderFilteredImage(outputImage)
                }
            }
        }
        
        private func renderFilteredImage(_ outputImage: CIImage) {
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                self.processedImage = UIImage(cgImage: cgImage)
            }
        }
    }
