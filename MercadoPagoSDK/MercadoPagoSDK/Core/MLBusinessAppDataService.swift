import Foundation

struct MLBusinessAppDataService {
    enum AppIdentifier: String {
        case meli = "ML"
        case mp = "MP"
        case other = "OTHER"
    }

    private let meliName: String = "mercadolibre"
    private let mpName: String = "mercadopago"
    private let meliDeeplink: String = "meli://instore/scan_qr"
    private let mpDeeplink: String = "mercadopago://instore/scan_qr"

    private func getAppName() -> String {
        guard let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String else { return "" }
        return appName.lowercased()
    }
}

// MARK: Public methods.
extension MLBusinessAppDataService {
    func getAppIdentifier() -> AppIdentifier {
        return isMp() ? .mp : .meli
    }

    func getAppVersion() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return version ?? ""
    }

    func isMeli() -> Bool {
        return getAppName().contains(meliName)
    }

    func isMp() -> Bool {
        return getAppName().contains(mpName)
    }

    func isMeliAlreadyInstalled() -> Bool {
        let url = URL(fileURLWithPath: meliDeeplink)
        return UIApplication.shared.canOpenURL(url)
    }

    func isMpAlreadyInstalled() -> Bool {
        let url = URL(fileURLWithPath: mpDeeplink)
        return UIApplication.shared.canOpenURL(url)
    }

    func appendLandingURLToString(_ urlString: String) -> String {
        if (isMeli() || isMp()),
            !["meli://", "mercadopago://"].contains(where: urlString.contains),
            let encodedURL = urlString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
            let prefix = MLBusinessAppDataService().isMeli() ? "meli://" : "mercadopago://"
            let landingURL = "\(prefix)webview/?url=\(encodedURL)"
            return landingURL
        }
        return urlString
    }
}
