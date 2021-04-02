//
//  ContentView.swift
//  CameraFeed
//
//  Created by Lekan Adeyeri on 3/27/21.
//

import SwiftUI
import AVFoundation

// send data, when the data updates the text and background updates.
// hold screen, when the screen is held, the background becomes more translucent.

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
    
    @State var opacityValue = 1.0
    
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
    //                                .onReceive(timerToTake) { time in
    //                                    camera.takePic()
    //                                }
    //                                .onReceive(timerToRetake) { time in
    //                                    camera.reTake()
    //                                }
    //                                .onReceive(timerToSave) { time in
    //                                    camera.savePic()
    //                                }
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
                            
                            Text("Loading...")
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
            self.session.stopRunning()
            
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
    
    func savePic() {
        
        let image = UIImage(data: self.picData)!
        
        let orientedImage = UIImage(cgImage: image.cgImage!, scale: image.scale, orientation: .up)
        
        // saving Image...
        UIImageWriteToSavedPhotosAlbum(orientedImage, nil, nil, nil)
        
        self.isSaved = true
        
        print("saved successfully")
        
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
