//
//  ContentView.swift
//  DlshogiOnCoreML
//
//  Created by Masatoshi Hidaka on 2022/01/12.
//

import SwiftUI
import CoreML

struct ContentView: View {
    @State var model: DlShogiResnet10Swish?
    @State var sampleIO: SampleIO?
    @State var msg = "-"
    
    func loadModel() {
        let config = MLModelConfiguration()
        config.computeUnits = .all//デバイス指定(all/cpuAndGPU/cpuOnly)
        model = try? DlShogiResnet10Swish(configuration: config)
        sampleIO = getSampleIO(batchSize: 1)
        msg = "Model Loaded!"
    }
    
    func runModel() {
        guard let model = model else {
            return
        }
        guard let sampleIO = sampleIO else {
            return
        }
        guard let pred = try? model.prediction(x1: sampleIO.x1, x2: sampleIO.x2) else {
            msg = "Error on prediction"
            return
        }
        let moveDiff = isArrayClose(expected: sampleIO.move, actual: pred.move)
        let resultDiff = isArrayClose(expected: sampleIO.result, actual: pred.result)
        msg = "move: \(moveDiff.1)\nresult: \(resultDiff.1)"
    }
    
    var body: some View {
        VStack {
            Button(action: loadModel) {
                Text("Load Model")
            }
            Button(action: runModel) {
                Text("Run Model")
            }
            Text(msg)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
