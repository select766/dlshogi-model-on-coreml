//
//  SampleIOLoader.swift
//  DlshogiOnCoreML
//
//  Created by Masatoshi Hidaka on 2022/01/22.
//

import Foundation
import CoreML

struct SampleIO {
    var x1: MLMultiArray
    var x2: MLMultiArray
    var move: MLMultiArray
    var result: MLMultiArray
}

func getSampleIO(batchSize: Int) -> SampleIO {
    // SampleIO.binの内容を決め打ち
    let totalBatchSize = 1024
    let x1RecordShape = [62,9,9]
    let x2RecordShape = [57,9,9]
    let moveRecordShape = [2187]
    let resultRecordShape = [1]
    
    guard let url = Bundle.main.url(forResource: "SampleIO", withExtension: "bin") else {
        fatalError("SampleIO.bin not found")
    }
    guard let data = try? Data(contentsOf: url) else {
        fatalError("Failed to read SampleIO.bin")
    }
    let arr = data.withUnsafeBytes {
        Array(UnsafeBufferPointer(start: $0.baseAddress!.assumingMemoryBound(to: Float.self), count: $0.count / MemoryLayout<Float>.size))
    }
    
    var ofs = 0
    var mmArrays: [MLMultiArray] = []
    for recordShape in [x1RecordShape, x2RecordShape, moveRecordShape, resultRecordShape] {
        var mmShape: [NSNumber] = [NSNumber(value: batchSize)]
        var recordSize = 1
        for dim in recordShape {
            mmShape.append(NSNumber(value: dim))
            recordSize *= dim
        }
        guard let mmArray = try? MLMultiArray(shape: mmShape, dataType: .float32) else {
            fatalError("Cannot allocate MLMultiArray")
        }
        let mmRawPtr = UnsafeMutablePointer<Float>(OpaquePointer(mmArray.dataPointer))
        for i in 0..<recordSize*batchSize {
            mmRawPtr[i] = arr[ofs+i]
        }
        //        for i in 0..<recordSize*batchSize {
        //            mmArray[i] = NSNumber(value: arr[ofs+i])
        //        }
        mmArrays.append(mmArray)
        ofs += totalBatchSize * recordSize
    }
    return SampleIO(x1: mmArrays[0], x2: mmArrays[1], move: mmArrays[2], result: mmArrays[3])
}
