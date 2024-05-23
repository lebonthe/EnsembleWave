//
//  UIViewController+attributedTextForm.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/6.
//

import UIKit
extension UIViewController {
    func attributedTextForm(content: String, size: CGFloat, kern: CGFloat, color: UIColor, font: String = "NotoSansTC-Medium") -> NSAttributedString {
        var attributedTitleString = NSAttributedString()
        guard let font = UIFont(name: "NotoSansTC-Medium", size: size) else { return attributedTitleString }
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .kern: kern,
            .foregroundColor: color
        ]
        attributedTitleString = NSAttributedString(string: content, attributes: titleAttributes)
        return attributedTitleString
    }
}

extension UIView {
    func attributedTextForm(content: String, size: CGFloat, kern: CGFloat, color: UIColor, font: String = "NotoSansTC-Medium") -> NSAttributedString {
        var attributedTitleString = NSAttributedString()
        guard let font = UIFont(name: "NotoSansTC-Medium", size: size) else { return attributedTitleString }
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .kern: kern,
            .foregroundColor: color
        ]
        attributedTitleString = NSAttributedString(string: content, attributes: titleAttributes)
        return attributedTitleString
    }
}
