import SwiftUI
import SwiftData
import WidgetKit

struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor<TodoItem>(\.position)])
    private var todos: [TodoItem]

    @State private var newTodoTitle = ""
    @State private var newTodoPriority: Priority = .medium
    @State private var showingSettings = false
    @State private var editingTodo: TodoItem?
    @State private var reminderTodo: TodoItem?
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            List {
                addSection
                todoSection
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.background)
            .navigationTitle("Slate")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .fontWeight(.medium)
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isInputFocused = false
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(item: $editingTodo) { todo in
                EditTodoView(todo: todo) {
                    reloadWidgets()
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .confirmationDialog(
                "Remind me",
                isPresented: Binding(
                    get: { reminderTodo != nil },
                    set: { if !$0 { reminderTodo = nil } }
                )
            ) {
                Button("In 10 seconds (test)") { scheduleReminder(seconds: 10) }
                Button("In 5 minutes") { scheduleReminder(minutes: 5) }
                Button("In 30 minutes") { scheduleReminder(minutes: 30) }
                Button("In 1 hour") { scheduleReminder(minutes: 60) }
                Button("In 3 hours") { scheduleReminder(minutes: 180) }
                Button("Cancel", role: .cancel) { reminderTodo = nil }
            }
        }
    }

    // MARK: - Sections

    private var addSection: some View {
        Section {
            HStack(spacing: Theme.spacingMD) {
                TextField("New todo...", text: $newTodoTitle)
                    .focused($isInputFocused)
                    .submitLabel(.done)
                    .onSubmit(addTodo)

                Menu {
                    ForEach(Priority.allCases) { p in
                        Button {
                            newTodoPriority = p
                        } label: {
                            Label(p.label, systemImage: p == newTodoPriority ? "checkmark" : "")
                        }
                    }
                } label: {
                    Image(systemName: "flag.fill")
                        .foregroundStyle(Theme.priorityColor(newTodoPriority))
                }

                Button(action: addTodo) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .disabled(newTodoTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .listRowSeparator(.hidden)
    }

    private var todoSection: some View {
        Section {
            if todos.isEmpty {
                ContentUnavailableView(
                    "No Todos",
                    systemImage: "checklist",
                    description: Text("Add a todo above to get started.")
                )
            } else {
                ForEach(todos) { todo in
                    TodoRow(todo: todo) {
                        toggleTodo(todo)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingTodo = todo
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            modelContext.delete(todo)
                            saveAndReload()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        if !todo.done {
                            Button {
                                reminderTodo = todo
                            } label: {
                                Label("Remind", systemImage: "bell")
                            }
                            .tint(.indigo)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: Theme.spacingSM, leading: Theme.spacingLG + 4, bottom: Theme.spacingSM, trailing: Theme.spacingLG))
                }
                .onDelete(perform: deleteTodos)
                .onMove(perform: moveTodos)
            }
        }
    }

    // MARK: - Actions

    private func addTodo() {
        let trimmed = newTodoTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let maxPosition = todos.map(\.position).max() ?? -1
        let item = TodoItem(
            title: trimmed,
            priority: newTodoPriority,
            position: maxPosition + 1
        )
        modelContext.insert(item)
        saveAndReload()

        newTodoTitle = ""
        newTodoPriority = .medium
    }

    private func toggleTodo(_ todo: TodoItem) {
        withAnimation(.snappy) {
            todo.done.toggle()
            todo.doneAt = todo.done ? .now : nil
        }
        saveAndReload()
    }

    private func deleteTodos(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(todos[index])
        }
        saveAndReload()
    }

    private func moveTodos(from source: IndexSet, to destination: Int) {
        var reordered = todos
        reordered.move(fromOffsets: source, toOffset: destination)
        for (i, todo) in reordered.enumerated() {
            todo.position = i
        }
        saveAndReload()
    }

    private func scheduleReminder(seconds: Int) {
        guard let todo = reminderTodo else { return }
        NotificationManager.shared.scheduleReminder(
            for: todo.id.uuidString,
            title: todo.title,
            after: TimeInterval(seconds)
        )
        reminderTodo = nil
    }

    private func scheduleReminder(minutes: Int) {
        scheduleReminder(seconds: minutes * 60)
    }

    private func saveAndReload() {
        try? modelContext.save()
        reloadWidgets()
    }

    private func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - TodoRow

struct TodoRow: View {
    let todo: TodoItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: Theme.spacingMD) {
            Button(action: onToggle) {
                Image(systemName: todo.done ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(todo.done ? Theme.success : Theme.priorityColor(todo.priority))
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)

            Text(todo.title)
                .strikethrough(todo.done)
                .foregroundStyle(todo.done ? Theme.textSecondary : Theme.textPrimary)

            Spacer()
        }
        .padding(.vertical, 2)
        .opacity(todo.done ? 0.5 : 1)
    }
}

// MARK: - EditTodoView

struct EditTodoView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var todo: TodoItem
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Title", text: $todo.title)
                }
                Section("Priority") {
                    Picker("Priority", selection: $todo.priority) {
                        ForEach(Priority.allCases) { p in
                            Text(p.label).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Due Date") {
                    Toggle("Has Due Date", isOn: Binding(
                        get: { todo.dueDate != nil },
                        set: { todo.dueDate = $0 ? .now : nil }
                    ))
                    if let _ = todo.dueDate {
                        DatePicker(
                            "Due",
                            selection: Binding(
                                get: { todo.dueDate ?? .now },
                                set: { todo.dueDate = $0 }
                            ),
                            displayedComponents: .date
                        )
                    }
                }
                Section("Status") {
                    Toggle("Completed", isOn: $todo.done)
                }
            }
            .navigationTitle("Edit Todo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
}
