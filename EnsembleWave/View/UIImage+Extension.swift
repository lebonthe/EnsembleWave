//
//  UIImage+Extension.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/7.
//

import UIKit

extension UIImage {
    static func from(text: String, font: UIFont = UIFont.systemFont(ofSize: 50), textColor: UIColor = .white, backgroundColor: UIColor = .clear, size: CGSize? = nil) -> UIImage? {
        let attributes = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: textColor
        ]

        let textSize = text.size(withAttributes: attributes)
        let drawingSize = size ?? textSize

        UIGraphicsBeginImageContextWithOptions(drawingSize, false, 0)
        backgroundColor.setFill()
        UIRectFill(CGRect(origin: .zero, size: drawingSize))
        text.draw(in: CGRect(x: (drawingSize.width - textSize.width) / 2, y: (drawingSize.height - textSize.height) / 2, width: textSize.width, height: textSize.height), withAttributes: attributes)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }
}
