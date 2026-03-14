import CoreGraphics

/// xkdpi のエラー定義
public enum DisplayError: Error, Equatable, Sendable {
    /// ディスプレイ情報の取得失敗
    case fetchFailed
    /// 指定されたモードIDが見つからない
    case modeNotFound(modeID: Int32)
    /// CGDisplayConfiguration の開始・完了失敗
    case configFailed
    /// モード切替の実行失敗（CGError.rawValue を保持）
    case switchFailed(Int32)
}
