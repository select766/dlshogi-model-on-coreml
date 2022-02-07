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
    
    func runModel() {
        guard let model = model else {
            msg = "Load model before run"
            return
        }
        
        let runner = ModelRunner(model: model, batchSize: batchSize, loadedModelComputeUnits: loadedModelComputeUnits, updateMessage: { msg in
            self.msg = msg
        })
        runner.start()
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
