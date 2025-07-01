import Foundation

public enum Remind: Codable, Equatable, Sendable {
    public struct Setting: Codable, Equatable, Sendable {
        public var dayOfWeek: DayOfWeek
        public var hour: Int

        public init(dayOfWeek: DayOfWeek, hour: Int) {
            self.dayOfWeek = dayOfWeek
            self.hour = hour
        }
    }

    case enabled(Setting)
    case disabled

    public static func make(_ dayOfWeek: DayOfWeek) -> Remind {
        .enabled(.init(dayOfWeek: dayOfWeek, hour: 9))
    }
}
