import Foundation

public class Updater<Value> {
    public private(set) var value: Value

    public init(_ value: Value) {
        self.value = value
    }

    public func update<NewValue>(_ new: NewValue, _ keyPath: WritableKeyPath<Value, NewValue>) -> Updater<Value> {
        value[keyPath: keyPath] = new
        return self
    }
}
