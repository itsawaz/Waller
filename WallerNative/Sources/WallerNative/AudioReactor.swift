import Cocoa
import AVFoundation
import Accelerate
import CoreAudio

class AudioReactor {
    static let shared = AudioReactor()
    
    private let engine = AVAudioEngine()
    private var isRunning = false
    
    // The current reactivity value (0.0 to 1.0)
    var currentLevel: CGFloat = 0.0
    // Callback fired continuously with the reactivity level
    var onUpdate: ((CGFloat) -> Void)?
    
    // DSP State
    private var filterState: Float = 0.0       // IIR low-pass carry
    private var peakHold: Float = 0.0          // Holds recent peak for smoother envelope
    private var peakDecayCounter: Int = 0      // Frames since last peak
    
    // Silence Gate
    private var isMacPlayingAudio: Bool = false
    private var silenceCheckTimer: Timer?
    
    // Noise floor: signals below this RMS are ignored entirely to kill
    // ambient hum, keyboard clicks, and breathing picked up by the mic.
    private let noiseFloor: Float = 0.005
    
    private init() {}
    
    func start() {
        guard !isRunning else { return }
        
        let inputNode = engine.inputNode
        let format = inputNode.inputFormat(forBus: 0)
        
        guard format.sampleRate > 0 else {
            print("[AudioReactor] Failed to get valid input format.")
            return
        }
        
        // Larger buffer = fewer callbacks = less CPU, still fast enough at ~23 Hz update rate
        inputNode.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] (buffer, _) in
            self?.processBuffer(buffer)
        }
        
        do {
            try engine.start()
            isRunning = true
            print("[AudioReactor] Started listening to microphone.")
            
            // Poll CoreAudio speaker state every 500ms
            silenceCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                self?.isMacPlayingAudio = AudioReactor.checkIfAudioIsPlayingGlobally()
            }
        } catch {
            print("[AudioReactor] Error starting engine: \(error.localizedDescription)")
        }
    }
    
    func stop() {
        guard isRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        silenceCheckTimer?.invalidate()
        silenceCheckTimer = nil
        isRunning = false
        currentLevel = 0.0
        filterState = 0.0
        peakHold = 0.0
        peakDecayCounter = 0
        onUpdate?(0.0)
        print("[AudioReactor] Stopped listening.")
    }
    
    private func processBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let channelDataValue = channelData.pointee
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return }
        
        // ── Gate: If Mac speakers aren't active, output silence ──
        guard isMacPlayingAudio else {
            filterState = 0.0
            peakHold = 0.0
            DispatchQueue.main.async {
                // Gentle fade to zero
                self.currentLevel = self.currentLevel * 0.92
                if self.currentLevel < 0.001 { self.currentLevel = 0 }
                self.onUpdate?(self.currentLevel)
            }
            return
        }
        
        // ── 1. IIR Low-Pass Filter (bass isolation) ──
        // alpha = 0.04 gives a very aggressive cutoff (~100 Hz at 44.1kHz).
        // This kills vocals, hi-hats, snares and only passes kick drums & sub-bass.
        let alpha: Float = 0.04
        var filteredBuffer = [Float](repeating: 0, count: frameLength)
        var carry = filterState
        
        for i in 0..<frameLength {
            carry = alpha * channelDataValue[i] + (1.0 - alpha) * carry
            filteredBuffer[i] = carry
        }
        filterState = carry
        
        // ── 2. RMS of filtered bass signal using vDSP ──
        var meanSquare: Float = 0.0
        vDSP_measqv(filteredBuffer, 1, &meanSquare, vDSP_Length(frameLength))
        let rms = sqrtf(meanSquare)
        
        // ── 3. Noise floor gate ──
        // If the bass RMS is below the noise floor, treat it as silence.
        guard rms > noiseFloor else {
            DispatchQueue.main.async {
                let smoothing = CGFloat(SettingsManager.shared.audioSmoothing)
                let decay = min(0.98, smoothing * 1.1)
                self.currentLevel = self.currentLevel * decay
                if self.currentLevel < 0.001 { self.currentLevel = 0 }
                self.onUpdate?(self.currentLevel)
            }
            return
        }
        
        // ── 4. Normalize & Peak Hold ──
        // Multiply to bring the tiny bass RMS into a visible 0-1 range.
        let multiplier: Float = 35.0
        var normalized = min(rms * multiplier, 1.0)
        
        // Peak hold: if a new peak arrives, latch it. Otherwise let it decay
        // over ~6 frames. This gives the visual a satisfying "hang" on big bass hits.
        if normalized > peakHold {
            peakHold = normalized
            peakDecayCounter = 0
        } else {
            peakDecayCounter += 1
            if peakDecayCounter > 4 {
                peakHold = peakHold * 0.92 // Gentle peak release
            }
        }
        
        // Blend current RMS with peak hold for smoother output
        normalized = normalized * 0.4 + peakHold * 0.6
        
        let level = CGFloat(normalized)
        
        DispatchQueue.main.async {
            let smoothing = CGFloat(SettingsManager.shared.audioSmoothing)
            
            // Envelope: separate attack (rise) and decay (fall) coefficients.
            // Low smoothing = punchy. High smoothing = cinematic.
            let attackCoeff = min(0.85, smoothing * 0.7)  // How quickly it rises
            let decayCoeff  = min(0.97, smoothing * 1.1)  // How slowly it falls
            
            if level > self.currentLevel {
                self.currentLevel = self.currentLevel * attackCoeff + level * (1.0 - attackCoeff)
            } else {
                self.currentLevel = self.currentLevel * decayCoeff + level * (1.0 - decayCoeff)
            }
            
            self.onUpdate?(self.currentLevel)
        }
    }
    
    // MARK: - CoreAudio Silence Gate
    
    private static func checkIfAudioIsPlayingGlobally() -> Bool {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        if AudioObjectGetPropertyData(UInt32(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID) != noErr {
            return false
        }
        
        var isRunning: UInt32 = 0
        var runSize = UInt32(MemoryLayout<UInt32>.size)
        var runAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        if AudioObjectGetPropertyData(deviceID, &runAddress, 0, nil, &runSize, &isRunning) != noErr {
            return false
        }
        
        return isRunning > 0
    }
}
