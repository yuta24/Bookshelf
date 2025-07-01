import Foundation
import WidgetKit
import WidgetUpdater

extension WidgetUpdater {
    actor Holder: Sendable {
        var flag: Bool

        init(flag: Bool) {
            self.flag = flag
        }

        func set(_ flag: Bool) {
            self.flag = flag
        }
    }

    static func generate(_ center: WidgetCenter) -> WidgetUpdater {
        let holder: Holder = .init(flag: false)
        return .init(
            setNeedNotify: { [holder] in
                await holder.set(true)
            },
            notifyIfNeed: { [holder] in
                guard await holder.flag else { return }
                center.reloadAllTimelines()
                await holder.set(false)
            }
        )
    }
}
