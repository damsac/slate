import AppIntents
import SwiftData
import WidgetKit

struct ToggleTodoIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Todo"
    static var description: IntentDescription = "Marks a todo as done or not done"

    @Parameter(title: "Todo ID")
    var todoID: String

    init() {}

    init(todoID: String) {
        self.todoID = todoID
    }

    func perform() async throws -> some IntentResult {
        let container = PersistenceConfig.modelContainer
        let context = ModelContext(container)

        let id = UUID(uuidString: todoID)
        let descriptor = FetchDescriptor<TodoItem>()
        let allTodos = try context.fetch(descriptor)

        if let todo = allTodos.first(where: { $0.id == id }) {
            todo.done.toggle()
            todo.doneAt = todo.done ? .now : nil
            try context.save()
        }

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
