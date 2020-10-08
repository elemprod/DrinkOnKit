//
//  DrinkOnKitUtility.swift
//  Utility and Helper Functions
//

import Foundation
import CoreBluetooth

public extension CBCharacteristic {
    
    /// Returns a formatted string containing the characteristic's Read / Write / Notify Permissions
    func formattedAccessString() -> String {
        var returnString = "Read: "
        returnString.append(boolString(value: self.properties.contains(.read)))
        returnString.append(", Write: ")
        returnString.append(boolString(value: self.properties.contains(.write)))
        returnString.append(", Notify: ")
        returnString.append(boolString(value: self.properties.contains(.notify)))
        return returnString
    }
    
    // Append True / False to the String
    private func boolString(value: Bool) -> String {
        if value == true {
            return "True"
        } else {
            return "False"
        }
    }
}

/// Execute a closure after a delay
///
/// - Parameters:
///   - delay: delay to insert in seconds
///   - closure: code to execute after delay

func delay(_ delay:Double, closure:@escaping ()->()) {
    let when = DispatchTime.now() + delay
    DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
}

/// Returns an UInt8 byte array representation of a UInt16 Value
extension Int16 {
    var byteArray : [UInt8] {
        let returnArray : [UInt8] = [UInt8(truncatingIfNeeded: self),
                                     UInt8(truncatingIfNeeded: (self >> 8))]
        return returnArray
    }
}


/// Returns an UInt8 byte array representation of a Float Value
extension Float {
    var byteArray : [UInt8] {
        let byte0 = UInt8(truncatingIfNeeded: (self.bitPattern >> 24))
        let byte1 = UInt8(truncatingIfNeeded: (self.bitPattern >> 16))
        let byte2 = UInt8(truncatingIfNeeded: (self.bitPattern >> 8))
        let byte3 = UInt8(truncatingIfNeeded: self.bitPattern)
        return [byte3, byte2, byte1, byte0]
    }
}

// Source: http://stackoverflow.com/a/35201226/2115352
extension Data {
    
    //// returns the unsigned 8 bit int encoded value stored at the index
    func uint8ValueAt(index : Int) -> UInt8? {
        if index >= self.count {
            return nil
        } else {
            return self[index]
        }
    }
    /// returns the signed 8 bit int encoded value stored at the index
    func int8ValueAt(index : Int) -> Int8? {
        guard let uint8Value : UInt8 = uint8ValueAt(index: index) else {
            return nil
        }
        return Int8(uint8Value)
    }
    
    /// returns the unsigned 16 bit int encoded value stored at the index
    func uint16ValueAt(index : Int) -> UInt16? {
        if index + 1 >= self.count {
            return nil
        } else {
            return (UInt16(self[index + 1]) << 8) | UInt16(self[index])
        }
    }
    /// returns the signed 16 bit int encoded value stored at the index
    func int16ValueAt(index : Int) -> Int16? {
        if index + 1 >= self.count {
            return nil
        } else {
            return Int16(bitPattern: (UInt16(self[index + 1]) << 8) | UInt16(self[index]))
        }
    }
    /// returns the unsigned 32 bit int encoded value stored at the index
    func uint32ValueAt(index : Int) -> UInt32? {
        if index + 3 >= self.count {
            return nil
        } else {
            var value: UInt32 = UInt32(self[index])
            value |= UInt32(self[index + 1]) << 8
            value |= UInt32(self[index + 2]) << 16
            value |= UInt32(self[index + 3]) << 24
            return value
        }
    }
    
    /// returns the signed 32 bit int encoded value stored at the index
    func int32ValueAt(index : Int) -> Int32? {
        guard let value = self.uint32ValueAt(index: index) else {
            return nil
        }
        return Int32(bitPattern: value)
    }
    
    /// returns the 32 bit float encoded value stored at the index
    func floatValueAt(index : Int) -> Float? {
        guard let value = self.uint32ValueAt(index: index) else {
            return nil
        }
        return Float(bitPattern:value)
    }
    
    /// Returns the utf8 (ascii) encoded character string represented by the data
    func utf8String() -> String? {
        return String(data: self, encoding: String.Encoding.utf8)
    }
    
    /// returns the utf8 (ascii) encoded character string starting at the index
    func utf8StringAt(index : Int) -> String? {
        if index + 1  >= self.count {
            return nil
        } else {
            let trimmedArray = Data(self[index..<self.count])
            return String(data: trimmedArray, encoding: String.Encoding.utf8)
        }
    }
    
    /** Decompress a 3 byte long uint8 data structure into
    *       a 4 byte uint8 long array.  The upper 2 bits of values are disgarded
    *       limiting the storage values to 6 bits in length. (0 to 63).
    */
    func decompressed423(index : Int) -> [UInt8]? {
       
        if index + 2  >= self.count {
            return nil
        }
        
        let out : [UInt8] = [
            self[index] & 0x3F,
            self[index + 1] & 0x3F,
            self[index + 2] & 0x3F,
            ((self[index] >> 6) & 0x03) | ((self[index + 1] >> 4) & 0x0C) | ((self[index + 2] >> 2) & 0x30)
        ]
        return out
    }

    var hexDescription: String {
        return reduce("") {$0 + String(format: "0x%02x,", $1)}
    }
    
    fileprivate func getByteArray(_ pointer: UnsafePointer<UInt8>) -> [UInt8] {
        let buffer = UnsafeBufferPointer<UInt8>(start: pointer, count: count)
        return [UInt8](buffer)
    }
    
}

extension String {
    
    subscript (i: Int) -> String {
        return self[i ..< i + 1]
        //return self[Range(i ..< i + 1)]
    }
    
    func substring(from: Int) -> String {
        return self[min(from, self.count) ..< self.count]
        //return self[Range(min(from, self.count) ..< self.count)]
    }
    
    func substring(to: Int) -> String {
        return self[0 ..< max(0, to)]
        //return self[Range(0 ..< max(0, to))]
    }
    
    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(self.count, r.lowerBound)),
                                            upper: min(self.count, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
        //return String(self[Range(start ..< end)])
    }
    
    /// Remove all spaces, line returns, etc from a string
    func removingWhitespaces() -> String {
        return components(separatedBy: .whitespaces).joined()
    }
    
    
    /// Remove all nulls from a string and trim leading and trailing whitespace
    var trimmed : String {
        var returnString = self.replacingOccurrences(of: "\0", with: "")
        returnString = returnString.trimmingCharacters(in: .whitespaces)
        return returnString
    }
    
    /// Returns a UTF8 encoded Data representaton of the String or nil if the conversion fails
    var UTF8Data: Data? {
        return self.data(using: String.Encoding.utf8, allowLossyConversion: true)
    }
    
    /// Returns a UTF8 encoded UInt8 array representaton of the String.
    var UTF8Array: [UInt8] {
        let byteArray: [UInt8] = Array(self.utf8)
        return byteArray
    }
}

/*
/// Test float to byte array to data and back conversion
func floatTest(value: Float) {
    print("Float Conversion Test Value \(value)")
    let testFloatByteArray : [UInt8] = value.byteArray
    print("Byte Array \(testFloatByteArray)")
    let testFloatData: Data = Data(testFloatByteArray)
    print("Data [\(testFloatData[0]),\(testFloatData[1]),\(testFloatData[2]),\(testFloatData[3])] ")
    let testConvertedBack : Float = testFloatData.floatValueAt(index: 0)!
    print("Converted Back \(testConvertedBack)")
    
    if value != testConvertedBack {
        print("** Error ** Converted Values Don't Match")
    }
}
*/
