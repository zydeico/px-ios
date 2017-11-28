//
//  BodyComponent.swift
//  TestAutolayout
//
//  Created by Demian Tejo on 10/19/17.
//  Copyright © 2017 Demian Tejo. All rights reserved.
//

import UIKit

class BodyComponent: NSObject, PXComponetizable {
    var props: BodyProps

    init(props: BodyProps) {
        self.props = props
    }

    public func hasInstructions() -> Bool {
        return props.instruction != nil
    }

    public func getInstructionsComponent() -> InstructionsComponent {
        let instructionsProps = InstructionsProps(instruction: props.instruction!, processingMode: props.processingMode)
        let instructionsComponent = InstructionsComponent(props: instructionsProps)
        return instructionsComponent
    }
    
    public func getPaymentMethodComponent() -> PXPaymentMethodBodyComponent {
        let pm = self.props.paymentResult.paymentData?.paymentMethod
        let image = MercadoPago.getImageForPaymentMethod(withDescription: (pm?._id)!)
        var amountTitle = String(self.props.amount)
        var amountDetail: String?
        if let payerCost = self.props.paymentResult.paymentData?.payerCost {
            if payerCost.installments > 1 {
                amountTitle = String(payerCost.installments) + "x " + MercadoPagoContext.getCurrency().symbol + " " + String(payerCost.installmentAmount)
                amountDetail = "(" +  String(payerCost.totalAmount) + ")"
            }
        }
        var issuerName : String?
        if (pm?.isCreditCard)! {
            issuerName = self.props.paymentResult.paymentData?.issuer?.name
        }
        let bodyProps = PXPaymentMethodBodyComponentProps(paymentMethodIcon: image!, amountTitle: amountTitle, amountDetail: amountDetail, paymentMethodDescription: "XXasdas", paymentMethodDetail: issuerName)
        return PXPaymentMethodBodyComponent(props: bodyProps)
    }
    
    func render() -> UIView {
        return BodyRenderer().render(body: self)
    }

}
class BodyProps: NSObject {
    var paymentResult: PaymentResult
    var instruction: Instruction?
    var processingMode: String
    var amount : Double
    init(paymentResult : PaymentResult, amount: Double, instruction: Instruction?, processingMode: String) {
        self.paymentResult = paymentResult
        self.instruction = instruction
        self.processingMode = processingMode
        self.amount = amount
    }
}
