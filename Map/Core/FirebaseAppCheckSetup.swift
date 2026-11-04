import FirebaseAppCheck
import FirebaseCore
import Foundation

/// Firebaseを利用する前にプロバイダーを設定する。Debugトークンを製品版へ含めない。
enum FirebaseAppCheckSetup {
    static func configure() {
        #if DEBUG
        // Personal Teamでの実機確認もDebug Providerを使用する。
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        #else
        AppCheck.setAppCheckProviderFactory(ProductionAppCheckProviderFactory())
        #endif
    }
}

private final class ProductionAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    nonisolated func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        AppAttestProvider(app: app)
    }
}
