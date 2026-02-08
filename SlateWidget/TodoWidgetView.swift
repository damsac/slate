import SwiftUI
import WidgetKit

struct TodoWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: TodoEntry

    var body: some View {
        switch family {
        case .systemMedium:
            mediumView
        case .accessoryRectangular:
            rectangularView
        case .accessoryCircular:
            circularView
        case .accessoryInline:
            inlineView
        default:
            mediumView
        }
    }

    // MARK: - Home Screen (Medium)

    private var mediumView: some View {
        Group {
            if entry.todos.isEmpty {
                VStack(spacing: 4) {
                    Image(systemName: "checklist")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("No Todos")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(entry.todos) { todo in
                        Button(intent: ToggleTodoIntent(todoID: todo.id)) {
                            HStack(spacing: 8) {
                                Image(systemName: todo.done ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(todo.done ? Theme.success : Theme.priorityColor(todo.priority))
                                    .font(.body)
                                Text(todo.title)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .strikethrough(todo.done)
                                    .foregroundStyle(todo.done ? .secondary : .primary)
                                Spacer(minLength: 0)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Lock Screen (Rectangular)

    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            if entry.todos.isEmpty {
                Text("No Todos")
                    .font(.headline)
                    .widgetAccentable()
            } else {
                ForEach(entry.todos.prefix(3)) { todo in
                    Button(intent: ToggleTodoIntent(todoID: todo.id)) {
                        HStack(spacing: 4) {
                            Image(systemName: todo.done ? "checkmark.circle.fill" : "circle")
                                .font(.caption2)
                            Text(todo.title)
                                .font(.caption2)
                                .lineLimit(1)
                                .strikethrough(todo.done)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Lock Screen (Circular)

    private var circularView: some View {
        let remaining = entry.todos.filter { !$0.done }.count
        return VStack(spacing: 2) {
            Text("\(remaining)")
                .font(.title2)
                .fontWeight(.bold)
                .widgetAccentable()
            Text("todo")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Lock Screen (Inline)

    private var inlineView: some View {
        let remaining = entry.todos.filter { !$0.done }.count
        return Text("\(remaining) todo\(remaining == 1 ? "" : "s") remaining")
    }
}
