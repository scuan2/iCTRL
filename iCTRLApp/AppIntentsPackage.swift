import AppIntents
import iCTRLIntents

struct iCTRLAppIntentsPackage: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] {
        [iCTRLIntentsPackage.self]
    }
}
