//
//  ContentView.swift
//  DlshogiOnCoreML
//
//  Created by Masatoshi Hidaka on 2022/01/12.
//

import SwiftUI
import CoreML

struct ContentView: View {
    @State var model: DlShogiResnet10SwishBatch?
    @State var sampleIO: SampleIO?
    @State var msg = "-"
    @State var batchSize = 64
    @State var loadedModelComputeUnits = ""
    
    func loadModel(computeUnits: MLComputeUnits) {
        let config = MLModelConfiguration()
        config.computeUnits = computeUnits//デバイス指定(all/cpuAndGPU/cpuOnly)
        model = try? DlShogiResnet10SwishBatch(configuration: config)
        msg = "Model Loaded!"
        switch computeUnits {
        case .cpuOnly:
            loadedModelComputeUnits = "CPU"
        case .cpuAndGPU:
            loadedModelComputeUnits = "GPU"
        case .all:
            loadedModelComputeUnits = "NE"
        @unknown default:
            fatalError()
        }
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
    
    func runModel() {
        guard let model = model else {
            return
        }
        let sampleIO = loadSampleIOIfNeeded()
        
        let timeStart = Date()
        guard let pred = try? model.prediction(x: sampleIO.x) else {
            msg = "Error on prediction"
            return
        }
        let timeEnd = Date()
        let elapsed = timeEnd.timeIntervalSince(timeStart)
        let moveDiff = isArrayClose(expected: sampleIO.move, actual: pred.move)
        let resultDiff = isArrayClose(expected: sampleIO.result, actual: pred.result)
        msg = "move: \(moveDiff.1)\nresult: \(resultDiff.1)\nelapsed: \(elapsed) sec\ncu=\(loadedModelComputeUnits)\nbs=\(sampleIO.x.shape[0])"
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Load Model")
                Button(action: {loadModel(computeUnits: .all)}) {
                    Text("NE")
                }.padding()
                Button(action: {loadModel(computeUnits: .cpuAndGPU)}) {
                    Text("GPU")
                }.padding()
                Button(action: {loadModel(computeUnits: .cpuOnly)}) {
                    Text("CPU")
                }.padding()
            }
            HStack {
                Text("Batch size")
                TextField("bs", value: $batchSize, formatter: NumberFormatter()).frame(width: 50, height: 10, alignment: .center)
            }
            Button(action: runModel) {
                Text("Run Model")
            }.padding()
            Text(msg).padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
