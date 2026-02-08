import Testing
@testable import Slate

@Suite("Priority")
struct PriorityTests {
    @Test("labels are capitalized")
    func labels() {
        #expect(Priority.high.label == "High")
        #expect(Priority.medium.label == "Medium")
        #expect(Priority.low.label == "Low")
    }

    @Test("sortOrder: high < medium < low")
    func sortOrder() {
        #expect(Priority.high.sortOrder < Priority.medium.sortOrder)
        #expect(Priority.medium.sortOrder < Priority.low.sortOrder)
    }

    @Test("CaseIterable has exactly 3 cases")
    func allCases() {
        #expect(Priority.allCases.count == 3)
    }
}

@Suite("TodoType")
struct TodoTypeTests {
    @Test("both cases exist")
    func allCases() {
        #expect(TodoType.allCases.count == 2)
        #expect(TodoType.allCases.contains(.today))
        #expect(TodoType.allCases.contains(.backlog))
    }
}

@Suite("TodoItem defaults")
struct TodoItemTests {
    @Test("default values")
    func defaults() {
        let item = TodoItem(title: "Test")
        #expect(item.title == "Test")
        #expect(item.done == false)
        #expect(item.doneAt == nil)
        #expect(item.priority == .medium)
        #expect(item.todoType == .today)
        #expect(item.dueDate == nil)
        #expect(item.position == 0)
    }

    @Test("custom values are applied")
    func customValues() {
        let item = TodoItem(
            title: "Custom",
            done: true,
            priority: .high,
            todoType: .backlog,
            position: 5
        )
        #expect(item.title == "Custom")
        #expect(item.done == true)
        #expect(item.priority == .high)
        #expect(item.todoType == .backlog)
        #expect(item.position == 5)
    }
}
