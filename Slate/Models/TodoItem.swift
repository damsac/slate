import Foundation
import SwiftData

enum Priority: String, Codable, CaseIterable, Identifiable {
    case high, medium, low

    var id: String { rawValue }

    var label: String {
        switch self {
        case .high: "High"
        case .medium: "Medium"
        case .low: "Low"
        }
    }

    var sortOrder: Int {
        switch self {
        case .high: 0
        case .medium: 1
        case .low: 2
        }
    }
}

enum TodoType: String, Codable, CaseIterable, Identifiable {
    case today, backlog

    var id: String { rawValue }

}

@Model
final class TodoItem {
    var id: UUID
    var title: String
    var done: Bool
    var doneAt: Date?
    var priority: Priority
    var todoType: TodoType
    var dueDate: Date?
    var position: Int
    var createdAt: Date

    init(
        title: String,
        done: Bool = false,
        priority: Priority = .medium,
        todoType: TodoType = .today,
        dueDate: Date? = nil,
        position: Int = 0,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.title = title
        self.done = done
        self.doneAt = nil
        self.priority = priority
        self.todoType = todoType
        self.dueDate = dueDate
        self.position = position
        self.createdAt = createdAt
    }
}
