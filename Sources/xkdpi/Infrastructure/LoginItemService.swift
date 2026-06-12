import Foundation
import ServiceManagement

/// ログイン時起動の登録状態を管理するインターフェース
public protocol LoginItemManaging: AnyObject {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}

/// ServiceManagement を使用したログイン項目管理
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
