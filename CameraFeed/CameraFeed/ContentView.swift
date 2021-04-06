//
//  ContentView.swift
//  CameraFeed
//
//  Created by Lekan Adeyeri on 3/27/21.
//

import Foundation
import SwiftUI
import AVFoundation
import Alamofire

struct ContentView: View {
    var body: some View {
        
        CameraView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct CameraView: View {
     
    @StateObject var camera = CameraModel()
    
    let timerToTake = Timer.publish(every: 3, on: .current, in: .common).autoconnect()
    let timerToRetake = Timer.publish(every: 4, on: .current, in: .common).autoconnect()
    let timerToSave = Timer.publish(every: 10, on: .current, in: .common).autoconnect()
    
    @GestureState var isDetectingLongPress = false
    @State var completedLongPress = false
    
    var longPress: some Gesture {
        LongPressGesture(minimumDuration:.infinity, maximumDistance: .infinity)
            .updating($isDetectingLongPress) { currentState, gestureState,
                    transaction in
                gestureState = currentState
                transaction.animation = Animation.easeIn(duration: 0.25)
            }
            .onEnded { finished in
                self.completedLongPress = finished
            }
    }

    var body: some View {
        
        ZStack {

            GeometryReader { geo in
                ZStack {
                            
                            ZStack {
                                
                                CameraPreview(camera: camera)
                                    .ignoresSafeArea(.all, edges: .all)
                                    .onReceive(timerToTake) { time in
                                        camera.takePic()
                                    }
                                    .onReceive(timerToRetake) { time in
                                        camera.reTake()
                                    }
                                    .onReceive(timerToSave) { time in
                                        camera.processPic()
                                    }
                            }

            
                    
                    VStack {

                        ZStack {

                            Rectangle()
                                .fill(Color.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .ignoresSafeArea(.all, edges: .all)
                                .opacity(self.isDetectingLongPress ?
                                            0.5 :
                                            (self.completedLongPress ? 0.5 : 1.0))

                            Text(camera.emotionString)
                                .font(.system(size: 60))
                                .opacity(self.isDetectingLongPress ?
                                            0.0 :
                                            (self.completedLongPress ? 0.0 : 1.0))
                        }
                        
                    }.frame(maxHeight: .infinity)
                    .gesture(longPress)
                    
                }
                .onAppear(perform: {
                    camera.Check()
                })
            }
        }
        
        
        
        
    }
}

// Camera Model...

class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    
    @Published var isTaken = false
    
    @Published var session = AVCaptureSession()
    
    @Published var alert = false
    
    // since were going to read pic data...
    @Published var output = AVCapturePhotoOutput()
    
    // preview
    @Published var preview : AVCaptureVideoPreviewLayer!
    
    // Pic Data...
    
    @Published var isSaved = false
    
    @Published var picData = Data(count: 0)
    
    @Published var emotionString = ""
    
    func Check() {
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setUp()
            return
            // Setting Up Session
        
        case .notDetermined:
            // requesting permission....
            AVCaptureDevice.requestAccess(for: .video) { (status) in
                
                if status{
                    self.setUp()
                }
            }
        case .denied:
            self.alert.toggle()
            return
        default:
            return
        }
    }
    
    func setUp() {
        
        // setting up camera...
        
        do {
            
            // setting configs...
            self.session.beginConfiguration()
            
            // change for your own
            
            let device = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back)
            
            let input = try AVCaptureDeviceInput(device: device!)
            
            // checking and adding to session...
            
            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }
            
            // same for output...
            
            if self.session.canAddOutput(self.output) {
                self.session.addOutput(self.output)
            }
            
            self.session.commitConfiguration()
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    // take and retake functions...
    
    func takePic() {
        
        DispatchQueue.global(qos: .background).async {
            self.output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
            // end
//            self.session.stopRunning()
            
            DispatchQueue.main.async {
                withAnimation{self.isTaken.toggle()}
            }
        }
    }
    
    func reTake() {
        
        DispatchQueue.global(qos: .background).async {
            
            self.session.startRunning()
            
            DispatchQueue.main.async {
                withAnimation{self.isTaken.toggle()}
                // clearing...
                self.isSaved = false
            }
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        if error != nil {
            return
        }
        
        print("pic taken...")
        
        guard let imageData = photo.fileDataRepresentation() else{return}
        
        self.picData = imageData
    }
    
    func processPic() {
        
        let backendURL = "https://fy481d31kk.execute-api.us-east-1.amazonaws.com/testStage/"
        
        let image = UIImage(data: self.picData)!
        
        let base64Image = (image.resized(withPercentage: 0.1)!.pngData()!.base64EncodedString())
        
        var someString = ""
        
//        let orientedImage = UIImage(cgImage: image.cgImage!, scale: image.scale, orientation: .up)
//
//        // saving Image...
//        UIImageWriteToSavedPhotosAlbum(orientedImage, nil, nil, nil)
        
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        self.isSaved = true
        
        self.emotionString = "Loading"

        AF.request(backendURL,
                   method: .post,
                   parameters: ["imageBase64": base64Image],
                   encoder: JSONParameterEncoder.default).responseJSON { response in
                    
                    let jsonDataString = "["+String(decoding: response.data!, as: UTF8.self)+"]"
                    
                    let jsonData = Data(jsonDataString.utf8)
                    
                    let decoder = JSONDecoder()
                    
                    print(jsonDataString)
                    
                    do {
                        
                        let dataValues = try decoder.decode([ReturnedDataObject].self, from: jsonData)
                        print(dataValues[0].data.emotions[0])
                        self.emotionString = dataValues[0].data.emotions[0].type

                    } catch {
                        
                        print("Error")
                        if error.localizedDescription == "The data couldn’t be read because it is missing." {
                            print("no emotion")
                            self.emotionString = "no emotion"
                            
                        } else {
                            print(error)
                        }

                    }

        }
        
//        let str = String(decoding: jsonData, as: UTF8.self)
//        print(str)
//
        
    }
}

// setting view for preview...

struct CameraPreview: UIViewRepresentable {
    
    @ObservedObject var camera: CameraModel
    
    func makeUIView(context: Context) -> UIView {
        
        let view = UIView(frame: UIScreen.main.bounds)
        
        camera.preview = AVCaptureVideoPreviewLayer(session: camera.session)
        camera.preview.frame = view.frame

        // Your Own Properties
        camera.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(camera.preview)
        
        // starting session
        camera.session.startRunning()
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
    
}

extension UIImage {
    func resized(withPercentage percentage: CGFloat) -> UIImage? {
        let canvas = CGSize(width: size.width * percentage, height: size.height * percentage)
        return UIGraphicsImageRenderer(size: canvas, format: imageRendererFormat).image {
            _ in draw(in: CGRect(origin: .zero, size: canvas))
        }
    }
    func resized(toWidth width: CGFloat) -> UIImage? {
        let canvas = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
        return UIGraphicsImageRenderer(size: canvas, format: imageRendererFormat).image {
            _ in draw(in: CGRect(origin: .zero, size: canvas))
        }
    }
}
