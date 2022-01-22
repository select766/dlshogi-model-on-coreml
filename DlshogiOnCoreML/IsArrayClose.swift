import Foundation
import CoreML

func isArrayClose(expected: MLMultiArray, actual: MLMultiArray, rtol: Float=1e-1, atol: Float=5e-2) -> (Bool, String) {
    let ea = UnsafeMutablePointer<Float>(OpaquePointer(expected.dataPointer))
    let aa = UnsafeMutablePointer<Float>(OpaquePointer(actual.dataPointer))
    var maxDiff: Float = 0.0
    for i in 0..<expected.count {
        let e = ea[i]
        let a = aa[i]
        let diff = abs(e-a)
        let tol = atol + rtol * abs(e)//numpyだとabs(第二引数)なので僅かに違う。expectedを基準にしたい
        if diff > tol {
            return (false, "Error at index \(i): \(e) != \(a)")
        }
        if diff > maxDiff {
            maxDiff = diff
        }
    }
    return (true, "Max difference: \(maxDiff)")
}
