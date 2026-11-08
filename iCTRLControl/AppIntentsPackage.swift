import AppIntents
import iCTRLIntents

struct iCTRLControlIntentsPackage: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] {
        [iCTRLIntentsPackage.self]
    }
}
