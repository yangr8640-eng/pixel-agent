import Foundation
import ServiceManagement

enum LaunchAtLoginService {
    static var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            SMAppService.mainApp.status == .enabled
        } else {
            false
        }
    }

    static func setEnabled(_ enabled: Bool) throws {
        guard #available(macOS 13.0, *) else {
            throw LaunchAtLoginError.unsupported
        }

        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}

enum LaunchAtLoginError: LocalizedError {
    case unsupported

    var errorDescription: String? {
        "Start at Login requires macOS 13 or newer."
    }
}
