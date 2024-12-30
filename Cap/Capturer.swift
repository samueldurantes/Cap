import Foundation
import AVFAudio
import ScreenCaptureKit
import OSLog
import Combine

class Capturer: ObservableObject, @unchecked Sendable {
    private let logger = Logger()
    private let captureEngine = CaptureEngine()
    
    @Published var isRunning = false
    
    private var streamConfiguration: SCStreamConfiguration {
        let streamConfig = SCStreamConfiguration()
        
        // Configure audio capture.
        streamConfig.capturesAudio = true
        
        // Set the capture interval at 60 fps.
        streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: 60)
        
        // Increase the depth of the frame queue to ensure high fps at the expense of increasing
        // the memory footprint of WindowServer.
        streamConfig.queueDepth = 5
        
        return streamConfig
    }
    
    /// Starts capturing audio
    func start() async {
        guard !isRunning else { return }
        
        do {
            let availableContent = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
            
            guard let display = availableContent.displays.first else {
                fatalError("No display available")
            }
            
            let excludedApps = availableContent.applications.filter { app in
                Bundle.main.bundleIdentifier == app.bundleIdentifier
            }

            let config = streamConfiguration
            let filter = SCContentFilter(display: display, excludingApplications: excludedApps, exceptingWindows: [])
            
            DispatchQueue.main.async {
                self.isRunning = true
            }
            
            for try await _ in captureEngine.startCapture(configuration: config, filter: filter) {}
        } catch {
            logger.error("\(error.localizedDescription)")
            
            DispatchQueue.main.async {
                self.isRunning = false
            }
        }
    }
    
    /// Stops capturing audio
    func stop() async {
        await captureEngine.stopCapture()
        
        DispatchQueue.main.async {
            self.isRunning = false
        }
    }
}

/// An object that wraps an instance of `SCStream`, and returns its results as an `AsyncThrowingStream`.
class CaptureEngine: NSObject, @unchecked Sendable {
    private let logger = Logger()

    private(set) var stream: SCStream?
    private var streamOutput: CaptureEngineStreamOutput?
    
    // Store the the startCapture continuation, so that you can cancel it when you call stopCapture().
    private var continuation: AsyncThrowingStream<Any, Error>.Continuation?
    
    func startCapture(configuration: SCStreamConfiguration, filter: SCContentFilter) -> AsyncThrowingStream<Any, Error> {
        AsyncThrowingStream<Any, Error> { continuation in
            let streamOutput = CaptureEngineStreamOutput(continuation)
            self.streamOutput = streamOutput

            do {
                stream = SCStream(filter: filter, configuration: configuration, delegate: streamOutput)

                try stream?.addStreamOutput(streamOutput, type: .screen, sampleHandlerQueue: .global())
                try stream?.addStreamOutput(streamOutput, type: .audio, sampleHandlerQueue: .global())
                stream?.startCapture()
            } catch {
                logger.error("When trying to start the capture an error: \(error)")
            }
        }
    }
    
    func stopCapture() async {
        do {
            try await stream?.stopCapture()
            continuation?.finish()
        } catch {
            continuation?.finish(throwing: error)
        }
    }
    
    func update(configuration: SCStreamConfiguration, filter: SCContentFilter) async {
        do {
            try await stream?.updateConfiguration(configuration)
            try await stream?.updateContentFilter(filter)
        } catch {
            logger.error("Failed to update the stream session: \(String(describing: error))")
        }
    }
    
    func addRecordOutputToStream(_ recordingOutput: SCRecordingOutput) async throws {
        try self.stream?.addRecordingOutput(recordingOutput)
    }
    
    func stopRecordingOutputForStream(_ recordingOutput: SCRecordingOutput) throws {
        try self.stream?.removeRecordingOutput(recordingOutput)
    }
}

/// A class that handles output from an SCStream, and handles stream errors.
private class CaptureEngineStreamOutput: NSObject, SCStreamOutput, SCStreamDelegate {
    private let logger = Logger()
    
    // Store the  startCapture continuation, so you can cancel it if an error occurs.
    private var continuation: AsyncThrowingStream<Any, Error>.Continuation?
    
    init(_ continuation: AsyncThrowingStream<Any, Error>.Continuation?) {
        self.continuation = continuation
    }
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
        guard sampleBuffer.isValid else { return }
        
        // Determine which type of data the sample buffer contains.
        switch outputType {
        case .audio:
            print(sampleBuffer)
        default:
            break
        }
    }
    
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        logger.error("The capture stop with an error: \(error)")
        continuation?.finish(throwing: error)
    }
}
