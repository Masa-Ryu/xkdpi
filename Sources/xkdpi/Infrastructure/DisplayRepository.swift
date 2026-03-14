import CoreGraphics

/// ディスプレイ情報リポジトリプロトコル
/// MacDisplayRepository（実機）と MockDisplayRepository（テスト）を交換可能にする DI 境界
public protocol DisplayRepository: Sendable {
    /// 接続中の全ディスプレイを返す（利用可能なモード一覧を含む）
    func fetchDisplays() throws -> [Display]
    /// 指定ディスプレイの利用可能な全モードを返す
    func fetchModes(for displayID: CGDirectDisplayID) throws -> [DisplayMode]
    /// 指定ディスプレイの現在のモードを返す
    func fetchCurrentMode(for displayID: CGDirectDisplayID) throws -> DisplayMode
    /// 指定ディスプレイのモードを切替える（CoreGraphics 委譲）
    func switchMode(displayID: CGDirectDisplayID, to modeID: Int32) throws
}
