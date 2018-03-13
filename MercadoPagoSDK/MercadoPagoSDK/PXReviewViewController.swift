//
//  PXReviewViewController.swift
//  MercadoPagoSDK
//
//  Created by Demian Tejo on 27/2/18.
//  Copyright © 2018 MercadoPago. All rights reserved.
//

import UIKit
import MercadoPagoPXTracking

class PXReviewViewController: PXComponentContainerViewController {
    
    // MARK: Tracking
    override open var screenName: String { get { return TrackingUtil.SCREEN_NAME_REVIEW_AND_CONFIRM } }
    override open var screenId: String { get { return TrackingUtil.SCREEN_ID_REVIEW_AND_CONFIRM } }
    
    // MARK: Definitions
    var footerView : UIView!
    var floatingButtonView : UIView!
    var termsConditionView: PXTermsAndConditionView!
    lazy var itemViews = [UIView]()
    fileprivate var viewModel: PXReviewViewModel!

    var callbackPaymentData: ((PaymentData) -> Void)
    var callbackConfirm: ((PaymentData) -> Void)
    var callbackExit: (() -> Void)
    
    // MARK: Lifecycle - Publics
    init(viewModel: PXReviewViewModel, callbackPaymentData : @escaping ((PaymentData) -> Void), callbackConfirm: @escaping ((PaymentData) -> Void), callbackExit: @escaping (() -> Void)) {
        self.viewModel = viewModel
        self.callbackPaymentData = callbackPaymentData
        self.callbackConfirm = callbackConfirm
        self.callbackExit = callbackExit
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupUI()
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.showsHorizontalScrollIndicator = false
        self.view.layoutIfNeeded()
    }
    
    func update(viewModel: PXReviewViewModel) {
        self.viewModel = viewModel
    }
}

// MARK: UI Methods
extension PXReviewViewController {
    
    fileprivate func setupUI() {
        navBarTextColor = ThemeManager.shared.getTitleColorForReviewConfirmNavigation()
        loadMPStyles()
        navigationController?.navigationBar.barTintColor = ThemeManager.shared.getTheme().highlightBackgroundColor()
        navigationItem.leftBarButtonItem?.tintColor = ThemeManager.shared.getTitleColorForReviewConfirmNavigation()
        if contentView.getSubviews().isEmpty {
            renderViews()
        }
    }
    
    fileprivate func renderViews() {
        
        self.contentView.prepareforRender()

        // Add title view.
        let titleView = getTitleComponentView()
        contentView.addSubview(titleView)
        PXLayout.pinTop(view: titleView).isActive = true
        PXLayout.centerHorizontally(view: titleView).isActive = true
        PXLayout.matchWidth(ofView: titleView).isActive = true

        // Add summary view.
        let summaryView = getSummaryComponentView()
        contentView.addSubviewToButtom(summaryView)
        PXLayout.centerHorizontally(view: summaryView).isActive = true
        PXLayout.matchWidth(ofView: summaryView).isActive = true
        
        // Add CFT view.
        if let cftView = getCFTComponentView() {
            contentView.addSubviewToButtom(cftView)
            PXLayout.centerHorizontally(view: cftView).isActive = true
            PXLayout.matchWidth(ofView: cftView).isActive = true
        }

        // Add item views
        itemViews = buildItemComponentsViews()
        for itemView in itemViews {
            contentView.addSubviewToButtom(itemView)
            PXLayout.centerHorizontally(view: itemView).isActive = true
            PXLayout.matchWidth(ofView: itemView).isActive = true
            itemView.addSeparatorLineToBottom(height: 1)
        }
        
        // Top Custom View
        if let topCustomView = getTopCustomView() {
            topCustomView.addSeparatorLineToBottom(height: 1)
            topCustomView.clipsToBounds = true
            contentView.addSubviewToButtom(topCustomView)
            PXLayout.matchWidth(ofView: topCustomView).isActive = true
            PXLayout.centerHorizontally(view: topCustomView).isActive = true
        }
        
        // Add payment method view.
        if let paymentMethodView = getPaymentMethodComponentView() {
            contentView.addSubviewToButtom(paymentMethodView)
            PXLayout.matchWidth(ofView: paymentMethodView).isActive = true
            PXLayout.centerHorizontally(view: paymentMethodView).isActive = true
        }
        
        // Bottom Custom View
        if let bottomCustomView = getBottomCustomView() {
            bottomCustomView.addSeparatorLineToTop(height: 1)
            bottomCustomView.addSeparatorLineToBottom(height: 1)
            bottomCustomView.clipsToBounds = true
            contentView.addSubviewToButtom(bottomCustomView)
            PXLayout.matchWidth(ofView: bottomCustomView).isActive = true
            PXLayout.centerHorizontally(view: bottomCustomView).isActive = true
        }

        // Add terms and conditions.
        if viewModel.shouldShowTermsAndCondition() {
            termsConditionView = getTermsAndConditionView()
            contentView.addSubview(termsConditionView)
            PXLayout.matchWidth(ofView: termsConditionView).isActive = true
            PXLayout.centerHorizontally(view: termsConditionView).isActive = true
            contentView.addSubviewToButtom(termsConditionView)
            termsConditionView.delegate = self
        }

        //Add Footer
        footerView = getFooterView()
        contentView.addSubviewToButtom(footerView)
        PXLayout.matchWidth(ofView: footerView).isActive = true
        PXLayout.centerHorizontally(view: footerView, to: contentView).isActive = true
        self.view.layoutIfNeeded()
        PXLayout.setHeight(owner: footerView, height: footerView.frame.height).isActive = true

        // Add floating button
        floatingButtonView = getFloatingButtonView()
        view.addSubview(floatingButtonView)
        PXLayout.setHeight(owner: floatingButtonView, height: viewModel.getFloatingConfirmViewHeight()).isActive = true
        PXLayout.matchWidth(ofView: floatingButtonView).isActive = true
        PXLayout.pinBottom(view: floatingButtonView, to: view, withMargin: 0).isActive = true

        // Add elastic header.
        addElasticHeader(headerBackgroundColor: summaryView.backgroundColor, navigationCustomTitle: PXReviewTitleComponentProps.DEFAULT_TITLE.localized)

        self.view.layoutIfNeeded()
        PXLayout.pinFirstSubviewToTop(view: self.contentView)?.isActive = true
        PXLayout.pinLastSubviewToBottom(view: self.contentView)?.isActive = true
        
        super.refreshContentViewSize()
    }
}

// MARK: Component Builders
extension PXReviewViewController {
    
    fileprivate func buildItemComponentsViews() -> [UIView] {
        var itemViews = [UIView]()
        let itemComponents = viewModel.buildItemComponents()
        for items in itemComponents {
            itemViews.append(items.render())
        }
        return itemViews
    }

    fileprivate func isConfirmButtonVisible() -> Bool {
        guard let floatingButton = self.floatingButtonView, let fixedButton = self.footerView else {
            return false
        }
        let floatingButtonCoordinates = floatingButton.convert(CGPoint.zero, from: self.view.window)
        let fixedButtonCoordinates = fixedButton.convert(CGPoint.zero, from: self.view.window)
        return fixedButtonCoordinates.y >= floatingButtonCoordinates.y
    }

    fileprivate func getPaymentMethodComponentView() -> UIView? {
        let action = PXComponentAction(label: "review_change_payment_method_action".localized_beta) {
            self.callbackPaymentData(self.viewModel.getClearPaymentData())
        }
        
        if let paymentMethodComponent = viewModel.buildPaymentMethodComponent(withAction:action) {
            return paymentMethodComponent.render()
        }
        
        return nil
    }
    
    fileprivate func getSummaryComponentView() -> UIView {
        let summaryComponent = viewModel.buildSummaryComponent(width: PXLayout.getScreenWidth())
        let summaryView = summaryComponent.render()
        return summaryView
    }
    
    fileprivate func getTitleComponentView() -> UIView {
        let titleComponent = viewModel.buildTitleComponent()
        return titleComponent.render()
    }
    
    fileprivate func getCFTComponentView() -> UIView? {
        if viewModel.hasPayerCostAddionalInfo() {
            let cftView = PXCFTComponentView(withCFTValue: viewModel.paymentData.payerCost?.getCFTValue(), titleColor: ThemeManager.shared.getTheme().labelTintColor(), backgroundColor: ThemeManager.shared.getTheme().highlightBackgroundColor())
            return cftView
        }
        return nil
    }

    fileprivate func getFloatingButtonView() -> PXContainedActionButtonView {
        let component = PXContainedActionButtonComponent(props: PXContainedActionButtonProps(title: "Confirmar".localized, action: {
            [weak self] in
            guard let strongSelf = self else {
                    return
            }
           strongSelf.confirmPayment()
        }))
        let containedButtonView = PXContainedActionButtonRenderer().render(component)
        return containedButtonView
    }
    
    fileprivate func getFooterView() -> UIView {
        let payAction = PXComponentAction(label: "Confirmar".localized) {
            [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.confirmPayment()
        }
        let cancelAction = PXComponentAction(label: "Cancelar".localized) {
            [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.cancelPayment()
        }
        let footerProps = PXFooterProps(buttonAction: payAction, linkAction: cancelAction)
        let footerComponent = PXFooterComponent(props: footerProps)
        return footerComponent.render()
    }
    
    fileprivate func getTermsAndConditionView() -> PXTermsAndConditionView {
        let termsAndConditionView = PXTermsAndConditionView()
        return termsAndConditionView
    }
    
    fileprivate func getTopCustomView() -> UIView? {
        if let component = self.viewModel.buildTopCustomComponent(), let componentView = component.render(store: PXCheckoutStore.sharedInstance) {
            return componentView
        }
        return nil
    }
    
    fileprivate func getBottomCustomView() -> UIView? {
        if let component = self.viewModel.buildBottomCustomComponent(), let componentView = component.render(store: PXCheckoutStore.sharedInstance) {
            return componentView
        }
        return nil
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        if !isConfirmButtonVisible() {
            self.floatingButtonView.alpha = 1
        } else {
            self.floatingButtonView.alpha = 0
        }
    }
}

//MARK: Actions.
extension PXReviewViewController: PXTermsAndConditionViewDelegate {
    
    fileprivate func confirmPayment() {
        self.hideNavBar()
        self.hideBackButton()
        self.callbackConfirm(self.viewModel.paymentData)
    }
    
    fileprivate func cancelPayment() {
        self.callbackExit()
    }
    
    func shouldOpenTermsCondition(_ title: String, screenName: String, url: URL) {
        let webVC = WebViewController(url: url, screenName: screenName, navigationBarTitle: title)
        webVC.title = title
        self.navigationController?.pushViewController(webVC, animated: true)
    }
}
