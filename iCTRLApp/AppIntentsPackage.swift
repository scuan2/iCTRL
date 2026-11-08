import AppIntents
import iCTRLIntents

@available(iOS 17.0, *)
struct iCTRLAppIntentsPackage: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] {
        [iCTRLIntentsPackage.self]
    }
}
