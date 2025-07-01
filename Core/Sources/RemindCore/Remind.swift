import Foundation

public enum Remind {
    case daily(hour: Int, minute: Int)
    case weekly(day: DayOfWeek, hour: Int, miniute: Int)
}
