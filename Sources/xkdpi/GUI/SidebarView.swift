import AppKit

/// 左ペイン: NSVisualEffectView 背景 + NSTableView でディスプレイ一覧を表示
final class SidebarView: NSView {

    // MARK: - Properties

    var displays: [Display] = [] {
        didSet { tableView.reloadData() }
    }

    var onDisplaySelected: ((Display) -> Void)?

    var selectedDisplayID: CGDirectDisplayID? {
        didSet { syncSelection() }
    }

    // MARK: - Subviews

    private let tableView = NSTableView()
    private let scrollView = NSScrollView()

    private static let rowIdentifier = NSUserInterfaceItemIdentifier("SidebarRow")
    private static let columnIdentifier = NSUserInterfaceItemIdentifier("DisplayColumn")

    // MARK: - Init

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError("XIB 非対応") }

    // MARK: - Setup

    private func setupViews() {
        // 背景: NSVisualEffectView (.sidebar)
        let effectView = NSVisualEffectView()
        effectView.material = .sidebar
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(effectView)

        // テーブルビュー
        let column = NSTableColumn(identifier: Self.columnIdentifier)
        column.title = ""
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.rowHeight = DesignTokens.Spacing.sidebarRowHeight
        tableView.selectionHighlightStyle = .regular
        tableView.style = .sourceList
        tableView.dataSource = self
        tableView.delegate = self

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        effectView.addSubview(scrollView)

        NSLayoutConstraint.activate([
            effectView.topAnchor.constraint(equalTo: topAnchor),
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: effectView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: effectView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: effectView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: effectView.bottomAnchor),
        ])
    }

    // MARK: - Public

    /// 指定ディスプレイIDの行のモード要約を更新する
    func updateRow(for displayID: CGDirectDisplayID, display: Display) {
        guard let index = displays.firstIndex(where: { $0.id == displayID }) else { return }
        displays[index] = display
        tableView.reloadData(forRowIndexes: IndexSet(integer: index),
                             columnIndexes: IndexSet(integer: 0))
    }

    // MARK: - Selection sync

    private func syncSelection() {
        guard let targetID = selectedDisplayID,
              let index = displays.firstIndex(where: { $0.id == targetID }) else { return }
        if tableView.selectedRow != index {
            tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        }
    }
}

// MARK: - NSTableViewDataSource

extension SidebarView: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        displays.count
    }
}

// MARK: - NSTableViewDelegate

extension SidebarView: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell: SidebarRowView
        if let reused = tableView.makeView(withIdentifier: Self.rowIdentifier, owner: nil) as? SidebarRowView {
            cell = reused
        } else {
            cell = SidebarRowView(frame: .zero)
            cell.identifier = Self.rowIdentifier
        }
        cell.configure(with: displays[row])
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = tableView.selectedRow
        guard row >= 0, row < displays.count else { return }
        let display = displays[row]
        selectedDisplayID = display.id
        onDisplaySelected?(display)
    }
}
