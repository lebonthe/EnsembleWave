//
//  CustomAlertController.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/1.
//

import UIKit
import SwiftEntryKit

class CustomAlertController {
    var title: String
    var message: String
    var okButtonTitle: String
    var againButtonTitle: String
    var onOKPressed: (() -> Void)?
    var onAgainPressed: (() -> Void)?

    init(title: String, message: String = "", okButtonTitle: String = "OK", againButtonTitle: String = "重來", onOKPressed: (() -> Void)? = nil, onAgainPressed: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.okButtonTitle = okButtonTitle
        self.againButtonTitle = againButtonTitle
        self.onOKPressed = onOKPressed
        self.onAgainPressed = onAgainPressed
    }

    func setOKButtonTitle(_ title: String) {
        okButtonTitle = title
    }

    func setAgainButtonTitle(_ title: String) {
        againButtonTitle = title
    }

    func show() {
        var attributes = EKAttributes.centerFloat
        attributes.windowLevel = .alerts
        attributes.displayDuration = .infinity
        attributes.entryBackground = .color(color: EKColor(UIColor.systemBackground))
        attributes.screenBackground = .color(color: EKColor(UIColor.black.withAlphaComponent(0.3)))
        attributes.shadow = .active(with: .init(color: .black, opacity: 0.3, radius: 8))
        attributes.roundCorners = .all(radius: 10)
        attributes.scroll = .enabled(swipeable: true, pullbackAnimation: .jolt)
        attributes.positionConstraints.size = .init(width: .offset(value: 20), height: .intrinsic)

        let titleLabel = EKProperty.LabelContent(text: title, style: .init(font: UIFont.boldSystemFont(ofSize: 16), color: EKColor(UIColor.label)))
        let messageLabel = EKProperty.LabelContent(text: message, style: .init(font: UIFont.systemFont(ofSize: 14), color: EKColor(UIColor.secondaryLabel)))

        let buttonFont = UIFont.systemFont(ofSize: 16)
        let okButtonLabel = EKProperty.LabelContent(text: okButtonTitle, style: .init(font: buttonFont, color: EKColor(UIColor.systemBlue)))
        let againButtonLabel = EKProperty.LabelContent(text: againButtonTitle, style: .init(font: buttonFont, color: EKColor(UIColor.systemRed)))

        let okButton = EKProperty.ButtonContent(label: okButtonLabel, backgroundColor: .clear, highlightedBackgroundColor: EKColor(UIColor.systemGray.withAlphaComponent(0.05))) {
            self.onOKPressed?()
            SwiftEntryKit.dismiss()
        }

        let againButton = EKProperty.ButtonContent(label: againButtonLabel, backgroundColor: .clear, highlightedBackgroundColor: EKColor(UIColor.systemGray.withAlphaComponent(0.05))) {
            self.onAgainPressed?()
            SwiftEntryKit.dismiss()
        }

        let buttonsBarContent = EKProperty.ButtonBarContent(with: okButton, againButton, separatorColor: EKColor(UIColor.lightGray), expandAnimatedly: true)
        let simpleMessage = EKSimpleMessage(title: titleLabel, description: messageLabel)
        let alertMessage = EKAlertMessage(simpleMessage: simpleMessage, buttonBarContent: buttonsBarContent)
        let contentView = EKAlertMessageView(with: alertMessage)

        SwiftEntryKit.display(entry: contentView, using: attributes)
    }
}
