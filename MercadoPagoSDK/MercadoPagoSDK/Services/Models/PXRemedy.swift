//
//  PXRemedy.swift
//  MercadoPagoSDK
//
//  Created by Eric Ertl on 16/03/2020.
//

import Foundation

struct PXRemedy: Codable {
    let cvv: PXInvalidCVV?
    let highRisk: PXHighRisk?
    let callForAuth: PXCallForAuth?
    let suggestedPaymentMethod: PXSuggestedPaymentMethod?
    let bottomMessage: PXRemedyBottomMessage?
    let trackingData: [String: String]?
}

// PXRemedy Helpers
extension PXRemedy {
    init() {
        self.init(cvv: nil, highRisk: nil, callForAuth: nil, suggestedPaymentMethod: nil, bottomMessage: nil, trackingData: nil)
    }
    
    var isEmpty: Bool {
        return cvv == nil && highRisk == nil && callForAuth == nil && suggestedPaymentMethod == nil
    }
    
    var shouldShowAnimatedButton: Bool {
        // These remedy types have its own animated button
        return cvv != nil || suggestedPaymentMethod != nil
    }
    
    var title: String? {
        // Get title for remedy
        if let title = suggestedPaymentMethod?.title {
            return title
        } else if let title = cvv?.title {
            return title
        } else if let title = highRisk?.title {
            return title
        }
        return nil
    }
}

struct PXInvalidCVV: Codable {
    let title: String?
    let message: String?
    let fieldSetting: PXFieldSetting?
}

struct PXHighRisk: Codable {
    let title: String?
    let message: String?
    let deepLink: String?
    let actionLoud: PXButtonAction?
}

struct PXCallForAuth: Codable {
    let title: String?
    let message: String?
}

struct PXFieldSetting: Codable {
    let name: String?
    let length: Int
    let title: String?
    let hintMessage: String?
}

struct PXButtonAction: Codable {
    let label: String?
}

struct PXSuggestedPaymentMethod: Codable {
    let title: String?
    let message: String?
    let actionLoud: PXButtonAction?
    let alternativePaymentMethod: PXRemedyPaymentMethod?
}

struct PXRemedyPaymentMethod: Codable {
    let customOptionId: String?
    let paymentMethodId: String?
    let paymentTypeId: String?
    let escStatus: String
    let issuerName: String?
    let lastFourDigit: String?
    let securityCodeLocation: String?
    let securityCodeLength: Int?
    let installmentsList: [PXPaymentMethodInstallment]?
    let installment: PXPaymentMethodInstallment?
}

struct PXPaymentMethodInstallment: Codable {
    let installments: Int
    let totalAmount: Double
}

struct PXRemedyBottomMessage: Codable {
    let message: String
    let backgroundColor: String
    let textColor: String
    let weight: String
    
    enum CodingKeys: String, CodingKey {
        case message
        case backgroundColor = "background_color"
        case textColor =  "text_color"
        case weight
    }
}
