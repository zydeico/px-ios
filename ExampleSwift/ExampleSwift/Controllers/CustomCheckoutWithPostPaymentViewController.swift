//
//  CustomCheckoutWithPostPaymentViewController.swift
//  ExampleSwift
//
//  Created by Ricardo Grajales Duque on 13/12/21.
//  Copyright © 2021 Juan Sebastian Sanzone. All rights reserved.
//

import UIKit
import MercadoPagoSDKV4

enum CustomCheckoutTestCase: String, CaseIterable {
    case approved
    case rejected
    case error

    var genericPayment: PXGenericPayment {
        switch self {
        case .approved:
            return PXGenericPayment(
                paymentStatus: .APPROVED,
                statusDetail: "Pago aprobado desde procesadora custom!"
            )
        case .rejected:
            return PXGenericPayment(
                paymentStatus: .REJECTED,
                statusDetail: "cc_amount_rate_limit_exceeded"
            )
        case .error:
            fatalError("genericPayment no debe ser invocado para este caso")
        }
    }
}

final class CustomCheckoutWithPostPaymentViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private var localeTextField: UITextField!
    @IBOutlet private var publicKeyTextField: UITextField!
    @IBOutlet private var preferenceIdTextField: UITextField!
    @IBOutlet private var accessTokenTextField: UITextField!
    @IBOutlet private var oneTapSwitch: UISwitch!
    @IBOutlet private var testCasePicker: UIPickerView!

    // MARK: - Variables
    private var checkout: MercadoPagoCheckout?

    // Collector Public Key
    private var publicKey: String = "TEST-a463d259-b561-45fe-9dcc-0ce320d1a42f"

    // Preference ID
    private var preferenceId: String = "737302974-34e65c90-62ad-4b06-9f81-0aa08528ec53"

    // Payer private key
    private var privateKey: String = "TEST-982391008451128-040514-b988271bf377ab11b0ace4f1ef338fe6-737303098"

    // MARK: - Actions
    @IBAction private func iniciarCheckout(_ sender: Any) {
        guard localeTextField.text?.count ?? 0 > 0,
            publicKeyTextField.text?.count ?? 0 > 0,
            preferenceIdTextField.text?.count ?? 0 > 0 else {
            let alert = UIAlertController(title: "Error", message: "Complete los campos requeridos para continuar", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            present(alert, animated: true)
            return
        }
        runMercadoPagoCheckoutWithLifecycleAndCustomProcessor()
//        runMercadoPagoCheckoutWithLifecycle()
    }

    @IBAction private func restablecerDatos(_ sender: Any) {
        localeTextField.text = ""
        publicKeyTextField.text = ""
        preferenceIdTextField.text = ""
        accessTokenTextField.text = ""
        oneTapSwitch.setOn(true, animated: true)
    }

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        let col1 = UIColor(red: 34.0 / 255.0, green: 211 / 255.0, blue: 198 / 255.0, alpha: 1)
        let col2 = UIColor(red: 145 / 255.0, green: 72.0 / 255.0, blue: 203 / 255.0, alpha: 1)
        gradient.colors = [col1.cgColor, col2.cgColor]
        view.layer.insertSublayer(gradient, at: 0)

        if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
           let infoPlist = NSDictionary(contentsOfFile: path) {
            // Initialize values from config
            publicKeyTextField.text = infoPlist["PX_COLLECTOR_PUBLIC_KEY"] as? String
            accessTokenTextField.text = infoPlist["PX_PAYER_PRIVATE_KEY"] as? String
        }

        localeTextField.text = "es-AR"
        preferenceIdTextField.text = preferenceId
        publicKeyTextField.text = publicKey
        accessTokenTextField.text = privateKey

        self.testCasePicker.delegate = self
        self.testCasePicker.dataSource = self
    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.modalPresentationStyle = .fullScreen
//        self.modalPresentationStyle = .fullScreen
    }

    // MARK: - Checkout Setup
    private func runMercadoPagoCheckoutWithLifecycle() {
        guard let publicKey = publicKeyTextField.text,
            let preferenceId = preferenceIdTextField.text,
            let language = localeTextField.text else {
            return
        }

        let builder = MercadoPagoCheckoutBuilder(publicKey: publicKey, preferenceId: preferenceId).setLanguage(language)
        if let privateKey = accessTokenTextField.text {
            builder.setPrivateKey(key: privateKey)
        }
        if oneTapSwitch.isOn {
            let advancedConfiguration = PXAdvancedConfiguration()
            advancedConfiguration.expressEnabled = true
            builder.setAdvancedConfiguration(config: advancedConfiguration)
        }

        let postPaymentConfig = PXPostPaymentConfiguration()
        postPaymentConfig.postPaymentNotificationName = .init("example postpayment")
        builder.setPostPaymentConfiguration(config: postPaymentConfig)
        suscribeToPostPaymentNotification(postPaymentConfig: postPaymentConfig)

        let checkout = MercadoPagoCheckout(builder: builder)
        if let myNavigationController = navigationController {
            checkout.start(navigationController: myNavigationController, lifeCycleProtocol: self)
        }
    }

    private func runMercadoPagoCheckoutWithLifecycleAndCustomProcessor() {
        // Create charge rules
        var pxPaymentTypeChargeRules: [PXPaymentTypeChargeRule] = []

        pxPaymentTypeChargeRules.append(
            PXPaymentTypeChargeRule.init(
                paymentTypeId: PXPaymentTypes.CREDIT_CARD.rawValue,
                amountCharge: 10.00
            )
        )

        // Create an instance of your custom payment processor
        let row = testCasePicker.selectedRow(inComponent: 0)
        let testCase = CustomCheckoutTestCase.allCases[row]
        let paymentProcessor: PXPaymentProcessor = CustomProcessor(with: testCase)

        // Create a payment configuration instance using the recently created payment processor
        let paymentConfiguration = PXPaymentConfiguration(paymentProcessor: paymentProcessor)

        // Add charge rules
        paymentConfiguration.addChargeRules(charges: pxPaymentTypeChargeRules)

        let checkoutPreference = PXCheckoutPreference(
            siteId: "MLA",
            payerEmail: "1234@gmail.com",
            items: [
                PXItem(
                    title: "iPhone 12",
                    quantity: 1,
                    unitPrice: 150.0
                )
            ]
        )

        // Add excluded methods
        checkoutPreference.addExcludedPaymentMethod("master")

        guard let publicKey = publicKeyTextField.text,
            let preferenceId = preferenceIdTextField.text,
            let language = localeTextField.text else {
            return
        }

        let builder = MercadoPagoCheckoutBuilder(
            publicKey: publicKey,
//            checkoutPreference: checkoutPreference,
            preferenceId: preferenceId,
            paymentConfiguration: paymentConfiguration
        )
        builder.setLanguage(language)

        if let privateKey = accessTokenTextField.text {
            builder.setPrivateKey(key: privateKey)
        }

        let postPaymentConfig = PXPostPaymentConfiguration()
        postPaymentConfig.postPaymentNotificationName = .init("example postpayment")
        builder.setPostPaymentConfiguration(config: postPaymentConfig)
        suscribeToPostPaymentNotification(postPaymentConfig: postPaymentConfig)

        // Instantiate a configuration object
        let configuration = PXAdvancedConfiguration()

        // Add custom PXDynamicViewController component
        configuration.dynamicViewControllersConfiguration = [CustomPXDynamicComponent()]

        // Configure the builder object
        builder.setAdvancedConfiguration(config: configuration)

        // Set the payer private key
        builder.setPrivateKey(key: privateKey)

        // Create Checkout reference
        checkout = MercadoPagoCheckout(builder: builder)

        // Start with your navigation controller.
        if let myNavigationController = navigationController {
            checkout?.start(navigationController: myNavigationController, lifeCycleProtocol: self)
        }
    }

    func suscribeToPostPaymentNotification(postPaymentConfig: PXPostPaymentConfiguration) {
        MercadoPagoCheckout.NotificationCenter.SubscribeTo.postPaymentAction(
            forName: postPaymentConfig.postPaymentNotificationName ?? .init("")
        ) { resultBlock in
            print("Got the notification")
            let postPayment = PostPaymentViewController(with: resultBlock)

            self.present(
                UINavigationController(rootViewController: postPayment),
                animated: true,
                completion: nil
            )
        }
    }
}

// MARK: Optional Lifecycle protocol implementation example.
extension CustomCheckoutWithPostPaymentViewController: PXLifeCycleProtocol {
    func finishCheckout() -> ((PXResult?) -> Void)? {
        return nil
    }

    func cancelCheckout() -> (() -> Void)? {
        return nil
    }

    func changePaymentMethodTapped() -> (() -> Void)? {
        return { () in
            print("px - changePaymentMethodTapped")
        }
    }
}

extension CustomCheckoutWithPostPaymentViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = ""
    }

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        return string != " "
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension CustomCheckoutWithPostPaymentViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return CustomCheckoutTestCase.allCases.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return CustomCheckoutTestCase.allCases[row].rawValue
    }
}

final class CustomProcessor: NSObject, PXPaymentProcessor {
    var testCase: CustomCheckoutTestCase

    init(with testCase: CustomCheckoutTestCase) {
        self.testCase = testCase
    }

    func startPayment(
        checkoutStore: PXCheckoutStore,
        errorHandler: PXPaymentProcessorErrorHandler,
        successWithBusinessResult: @escaping ((PXBusinessResult) -> Void),
        successWithPaymentResult: @escaping ((PXGenericPayment) -> Void)
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: { [self] in
            guard testCase != .error else {
                errorHandler.showError()
                return
            }
            successWithPaymentResult(testCase.genericPayment)
        })
    }

    func paymentProcessorViewController() -> UIViewController? {
        return nil
    }

    func support() -> Bool {
        return true
    }
}

final class PostPaymentViewController: UIViewController {
    private let resultBlock: MercadoPagoCheckout.PostPayment.ResultBlock

    init(with resultBlock: @escaping MercadoPagoCheckout.PostPayment.ResultBlock) {
        self.resultBlock = resultBlock
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        self.navigationItem.leftBarButtonItem = .init(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(didTapCancel)
        )

        let rejectedButton = UIButton()
        rejectedButton.backgroundColor = .red
        rejectedButton.setTitle("Rechazar", for: .normal)
        rejectedButton.addTarget(self, action: #selector(didTapRejected), for: .touchUpInside)

        let approvedButton = UIButton()
        approvedButton.backgroundColor = .green
        approvedButton.setTitle("Aprobar", for: .normal)
        approvedButton.addTarget(self, action: #selector(didTapApproved), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [rejectedButton, approvedButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.distribution = .fillEqually
        stack.axis = .vertical

        self.view.backgroundColor = .white
        self.view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    @objc
    func didTapCancel() {
        dismissWithResult(.cancelled)
    }

    @objc
    func didTapRejected() {
        dismissWithResult(.rejected)
    }

    @objc
    func didTapApproved() {
        dismissWithResult(.approved)
    }

    private func dismissWithResult(_ testCase: PostPaymentTestCase) {
        let payment = testCase.genericPayment
        self.dismiss(animated: true) { [resultBlock] in
            resultBlock(payment)
        }
    }
}

enum PostPaymentTestCase {
    case cancelled
    case rejected
    case approved

    var genericPayment: PXGenericPayment? {
        switch self {
        case .approved:
            return PXGenericPayment(
                paymentStatus: .APPROVED,
                statusDetail: "PostPayment Approved"
            )
        case .rejected:
            return PXGenericPayment(
                paymentStatus: .REJECTED,
                statusDetail: "PostPayment Rejected"
            )
        case .cancelled:
            return nil
        }
    }
}
