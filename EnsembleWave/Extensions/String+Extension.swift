//
//  String+Extension.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/8.
//

import Foundation
import CryptoKit
extension String {
    var md5: String {
        let computed = Insecure.MD5.hash(data: self.data(using: .utf8) ?? Data())
        return computed.map { String(format: "%02hhx", $0) }.joined()
    }
}
