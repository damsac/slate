import WidgetKit
import SwiftData
import Foundation

struct TodoEntry: TimelineEntry {
    let date: Date
    let todos: [TodoSnapshot]
}

struct TodoSnapshot: Identifiable {
    let id: String
    let title: String
    let done: Bool
    let priority: Priority
}

struct TodoTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodoEntry {
        TodoEntry(date: .now, todos: [
            TodoSnapshot(id: UUID().uuidString, title: "Sample todo", done: false, priority: .medium),
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (TodoEntry) -> Void) {
        let entry = fetchEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodoEntry>) -> Void) {
        let entry = fetchEntry()
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }

    private func fetchEntry() -> TodoEntry {
        do {
            let container = PersistenceConfig.modelContainer
            let context = ModelContext(container)
            var descriptor = FetchDescriptor<TodoItem>(
                sortBy: [SortDescriptor<TodoItem>(\.position)]
            )
            descriptor.fetchLimit = 5
            let todos = try context.fetch(descriptor).sorted { !$0.done && $1.done }
            let snapshots = todos.map { todo in
                TodoSnapshot(
                    id: todo.id.uuidString,
                    title: todo.title,
                    done: todo.done,
                    priority: todo.priority
                )
            }
            return TodoEntry(date: .now, todos: snapshots)
        } catch {
            return TodoEntry(date: .now, todos: [])
        }
    }
}
