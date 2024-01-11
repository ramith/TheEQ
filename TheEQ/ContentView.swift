import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var bandValues = Array(repeating: Float(0), count: 10)
    @State private var filePath: String = ""
    @State private var isPlaying = false

    private var audioEngine = AVAudioEngine()
    private var audioPlayerNode = AVAudioPlayerNode()
    private var equalizer = AVAudioUnitEQ(numberOfBands: 10)

    init() {
        setupAudioEngine()
    }

    var body: some View {
        VStack {
            HStack {
                TextField("File Path", text: $filePath)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(true)

                Button("Select File") {
                    selectFile()
                }
            }
            .padding()

            VStack(spacing: 20) {
                ForEach(0..<bandValues.count, id: \.self) { index in
                    EqualizerBand(bandValue: $bandValues[index], label: "\(frequencyLabels[index]) Hz", bandIndex: index, adjustBandGain: adjustBandGain)
                }
            }
            .padding()

            Button(action: togglePlay) {
                Text(isPlaying ? "Stop" : "Play")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
                    .background(isPlaying ? Color.red : Color.green)
                    .cornerRadius(10)
            }
            .padding()
        }
        
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { _ in
                   stopMusic()
        }
    }

    private func stopMusic() {
            if isPlaying {
                audioPlayerNode.stop()
                isPlaying = false
            }
        }
    
    private func setupAudioEngine() {
        let frequencies = [31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
        for i in 0..<equalizer.bands.count {
            equalizer.bands[i].frequency = Float(frequencies[i])
            equalizer.bands[i].bandwidth = 0.5
            equalizer.bands[i].gain = 0
            equalizer.bands[i].filterType = .parametric
            equalizer.bands[i].bypass = false
        }

        audioEngine.attach(audioPlayerNode)
        audioEngine.attach(equalizer)

        audioEngine.connect(audioPlayerNode, to: equalizer, format: nil)
        audioEngine.connect(equalizer, to: audioEngine.mainMixerNode, format: nil)

        do {
            try audioEngine.start()
        } catch {
            print("Audio Engine failed to start: \(error)")
        }
    }

    private func adjustBandGain(bandIndex: Int, gain: Float) {
        equalizer.bands[bandIndex].gain = gain
    }

    private func togglePlay() {
        if isPlaying {
            audioPlayerNode.stop()
            isPlaying = false
        } else {
            if !filePath.isEmpty {
                do {
                    let fileURL = URL(fileURLWithPath: filePath)
                    let file = try AVAudioFile(forReading: fileURL)
                    audioPlayerNode.scheduleFile(file, at: nil)
                    audioPlayerNode.play()
                    isPlaying = true
                } catch {
                    print("Failed to play file: \(error)")
                }
            }
        }
    }

    
    
    
    private func selectFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [UTType.audio]

        if panel.runModal() == .OK {
            self.filePath = panel.url?.path ?? ""
        }
    }

    private var frequencyLabels: [Int] {
        [31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
    }
}

struct EqualizerBand: View {
    @Binding var bandValue: Float
    var label: String
    var bandIndex: Int
    var adjustBandGain: (Int, Float) -> Void

    var body: some View {
        HStack {
            Text(label)
            Slider(value: $bandValue, in: -24...24, step: 1) { _ in
                adjustBandGain(bandIndex, bandValue)
            }
            Text("\(bandValue, specifier: "%.0f") dB")
        }
    }
}
