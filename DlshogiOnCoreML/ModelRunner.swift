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
    var loadedModelComputeUnits: String;
    var updateMessage: (String) -> Void;
    init(model: DlShogiResnet10SwishBatch, batchSize: Int, loadedModelComputeUnits: String, updateMessage: @escaping (String) -> Void) {
        self.model = model
        self.batchSize = batchSize
        self.loadedModelComputeUnits = loadedModelComputeUnits
        self.updateMessage = updateMessage
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
        guard let pred = try? model.prediction(x: sampleIO.x) else {
            msg("Error on prediction")
            return
        }
        let timeEnd = Date()
        let elapsed = timeEnd.timeIntervalSince(timeStart)
        let moveDiff = isArrayClose(expected: sampleIO.move, actual: pred.move)
        let resultDiff = isArrayClose(expected: sampleIO.result, actual: pred.result)
        msg("move: \(moveDiff.1)\nresult: \(resultDiff.1)\nelapsed: \(elapsed) sec\ncu=\(loadedModelComputeUnits)\nbs=\(sampleIO.x.shape[0])")
    }
    override func main() {
        runModel()
    }
}
