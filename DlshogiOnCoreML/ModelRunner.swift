//
//  ModelRunner.swift
//  DlshogiOnCoreML
//
//  Created by Masatoshi Hidaka on 2022/02/08.
//

import Foundation

var sampleIO: SampleIO?

class ModelRunner : Thread {
    var model: DlShogiResnet10SwishBatch
    var batchSize: Int
    var loadedModelComputeUnits: String
    var updateMessage: (String) -> Void
    var stop: Bool
    var duration: TimeInterval
    
    init(model: DlShogiResnet10SwishBatch, batchSize: Int, loadedModelComputeUnits: String, duration: TimeInterval, updateMessage: @escaping (String) -> Void) {
        self.model = model
        self.batchSize = batchSize
        self.loadedModelComputeUnits = loadedModelComputeUnits
        self.duration = duration
        self.updateMessage = updateMessage
        self.stop = false
        super.init()
    }
    
    func loadSampleIOIfNeeded() -> SampleIO {
        if let s = sampleIO {
            if s.x.shape[0].intValue != batchSize {
                let news = getSampleIO(batchSize: batchSize)
                sampleIO = news
                return news
            } else {
                return s
            }
        } else {
            let news = getSampleIO(batchSize: batchSize)
            sampleIO = news
            return news
        }
    }
    
    func msg(_ message: String) {
        DispatchQueue.main.async {
            self.updateMessage(message)
        }
    }
    
    func runModel() {
        msg("Started on thread")
        let sampleIO = loadSampleIOIfNeeded()
        
        let timeStart = Date()
        let timeWhenEnd = timeStart + duration
        var pred: DlShogiResnet10SwishBatchOutput?
        var timeNow = Date()
        var sampleCount = 0
        var lastReportTime = Date()
        var sampleCountOfLastReport = 0
        repeat {
            pred = try? model.prediction(x: sampleIO.x)
            if pred == nil {
                msg("Prediction error")
                return
            }
            timeNow = Date()
            sampleCount += batchSize
            let timeFromLastReport = timeNow.timeIntervalSince(lastReportTime)
            if timeFromLastReport >= 10.0 {
                let samplesBetweenReport = sampleCount - sampleCountOfLastReport
                let samplePerSec = Double(samplesBetweenReport) / timeFromLastReport
                msg("\(timeNow.timeIntervalSince(timeStart))sec, \(samplePerSec) samples / sec")
                lastReportTime = timeNow
                sampleCountOfLastReport = sampleCount
            }
        } while timeWhenEnd > timeNow && !stop
        let timeEnd = Date()
        
        let elapsed = timeEnd.timeIntervalSince(timeStart)
        guard let pred = pred else {
            return
        }
        let samplePerSec = Double(sampleCount) / elapsed
        let moveDiff = isArrayClose(expected: sampleIO.move, actual: pred.move)
        let resultDiff = isArrayClose(expected: sampleIO.result, actual: pred.result)
        msg("move: \(moveDiff.1)\nresult: \(resultDiff.1)\nelapsed: \(elapsed) sec\ncu=\(loadedModelComputeUnits)\nbs=\(sampleIO.x.shape[0])\n\(samplePerSec) samples / sec")
    }
    override func main() {
        runModel()
    }
}
