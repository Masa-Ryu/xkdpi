import Foundation
import ServiceManagement

/// Interface that manages launch-at-login registration state.
public protocol LoginItemManaging: AnyObject {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}

/// Login item management backed by ServiceManagement.
public final class LoginItemService: LoginItemManaging {

    public init() {}

    public var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    public func setEnabled(_ enabled: Bool) throws {
        if enabled {
            guard SMAppService.mainApp.status != .enabled else { return }
            try SMAppService.mainApp.register()
        } else {
            guard SMAppService.mainApp.status == .enabled else { return }
            try SMAppService.mainApp.unregister()
        }
    }
}
