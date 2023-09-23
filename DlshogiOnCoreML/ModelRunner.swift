//
//  ModelRunner.swift
//  DlshogiOnCoreML
//
//  Created by Masatoshi Hidaka on 2022/02/08.
//

import Foundation
import os

let logger = Logger(subsystem: "jp.outlook.select766.DlshogiOnCoreML", category: "main")

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
    
    func log(_ obj: Any) {
        do {
            //　シリアライズできないデータが来ると、 NSInvalidArgumentException が来て
            // これはNSExceptionのサブクラスでありswiftのcatchで処理できず落ちる
            let data = try JSONSerialization.data(withJSONObject: obj, options: [])
            guard let str = String(data: data, encoding: .utf8) else {
                logger.error("Failed to write log")
                return
            }
            logger.log("\(str, privacy: .public)") // 直接Stringは渡せない
        } catch {
            logger.error("Failed to write log")
        }
    }
    
    func runModel() {
        msg("Started on thread")
        log(["type": "start", "cu": loadedModelComputeUnits, "bs": batchSize])
        let sampleIO = loadSampleIOIfNeeded()
        
        let timeStart = Date()
        let timeWhenEnd = timeStart + duration
        var pred: DlShogiResnet10SwishBatchOutput?
        var timeNow = Date()
        var sampleCount = 0
        var lastReportTime = Date()
        var sampleCountOfLastReport = 0
        repeat {
            pred = try? model.prediction(input: sampleIO.x)
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
                let elapsed = timeNow.timeIntervalSince(timeStart)
                msg("\(elapsed)sec, \(samplePerSec) samples / sec")
                log(["type": "progress", "elapsed": elapsed, "samplePerSec": samplePerSec])
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
        let moveDiff = isArrayClose(expected: sampleIO.move, actual: pred.output_policy)
        let resultDiff = isArrayClose(expected: sampleIO.result, actual: pred.output_value)
        msg("move: \(moveDiff.1)\nresult: \(resultDiff.1)\nelapsed: \(elapsed) sec\ncu=\(loadedModelComputeUnits)\nbs=\(sampleIO.x.shape[0])\n\(samplePerSec) samples / sec")
        log(["type": "end", "elapsed": elapsed, "samplePerSec": samplePerSec, "moveDiff": moveDiff.1, "resultDiff": resultDiff.1])
    }
    override func main() {
        runModel()
    }
}
