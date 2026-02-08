// ===========================================
// Daily App — Data Models
// ===========================================
// Three core tables: User, Task, DailyTask
// Task = backlog items + recurring templates
// DailyTask = a concrete instance pinned to a date
// ===========================================

// ----- Enums -----

type Priority = "high" | "medium" | "low";

type Frequency = "daily" | "weekly";

type DailyTaskSource =
  | "recurring"  // auto-generated from a recurring Task
  | "backlog"    // pulled in from backlog during planning
  | "custom";    // one-off, typed in during planning

type DailyTaskStatus = "pending" | "completed" | "skipped";

type ReviewOutcome =
  | "moved"      // → tomorrow
  | "backlogged" // → back to backlog
  | "dropped";   // gone

// ----- Core Models -----

interface User {
  id: string;
  email: string;
  timezone: string;                  // e.g. "America/Chicago"
  morning_notification_time: string; // e.g. "07:00" — "Plan your day" nudge
  evening_notification_time: string; // e.g. "21:30" — "Review your day" nudge
  created_at: string;
}

interface Task {
  id: string;
  user_id: string;

  title: string;
  priority: Priority;

  // Backlog items can have a due date, recurring ones don't need it
  due_date: string | null;           // e.g. "2026-02-10"

  // Recurrence — null means it's a plain backlog item
  is_recurring: boolean;
  recurrence: RecurrenceRule | null;

  created_at: string;
  archived: boolean;                 // soft delete / completed backlog item
}

interface RecurrenceRule {
  frequency: Frequency;
  days_of_week: number[] | null;     // 0=Sun, 1=Mon, ..., 6=Sat. null if daily
  time: string | null;               // e.g. "22:00" for "Go to sleep at 10pm"
  reminder_offset_min: number;       // e.g. 30 → notify 30 min before time
}

interface DailyTask {
  id: string;
  user_id: string;
  date: string;                      // "2026-02-07" — which day this belongs to

  // Where it came from
  source: DailyTaskSource;
  task_id: string | null;            // FK to Task (null for custom one-offs)

  // Denormalized so daily view doesn't need joins
  title: string;
  priority: Priority;

  // Optional time + notification
  time: string | null;               // "14:30" — when this should happen
  reminder_offset_min: number;       // 30 → notify at 14:00

  // State
  status: DailyTaskStatus;
  completed_at: string | null;

  // End-of-day review (null until reviewed or auto-rolled)
  review_outcome: ReviewOutcome | null;

  // Ordering within the day (for manual reorder later)
  sort_order: number;
}

// ===========================================
// How the pieces connect
// ===========================================
//
//  ┌──────────┐
//  │   User   │
//  └────┬─────┘
//       │ has many
//       ▼
//  ┌──────────┐        ┌─────────────┐
//  │   Task   │───────▶│DailyTask    │
//  │          │ spawns │(per-day      │
//  │ template │        │ instance)    │
//  │ /backlog │        └─────────────┘
//  └──────────┘
//
// Task is the source of truth:
//   - Recurring? → system creates DailyTasks each morning
//   - Backlog?   → user pulls into a day during planning
//   - Neither?   → user creates a custom DailyTask directly
//
// DailyTask is what the UI renders.
// All reads for "Today" screen query DailyTask WHERE date = today.
// All reads for "Backlog" screen query Task WHERE is_recurring = false AND archived = false.
//
// ===========================================


// ===========================================
// Example data matching the UI mocks
// ===========================================

const exampleUser: User = {
  id: "usr_1",
  email: "me@example.com",
  timezone: "America/Chicago",
  morning_notification_time: "07:00",
  evening_notification_time: "21:30",
  created_at: "2026-01-15T00:00:00Z",
};

const exampleTasks: Task[] = [
  // Recurring tasks (templates)
  {
    id: "task_1",
    user_id: "usr_1",
    title: "Morning meditation",
    priority: "high",
    due_date: null,
    is_recurring: true,
    recurrence: {
      frequency: "daily",
      days_of_week: null,
      time: "07:00",
      reminder_offset_min: 0,
    },
    created_at: "2026-01-15T00:00:00Z",
    archived: false,
  },
  {
    id: "task_2",
    user_id: "usr_1",
    title: "Take out trash",
    priority: "medium",
    due_date: null,
    is_recurring: true,
    recurrence: {
      frequency: "weekly",
      days_of_week: [4], // Thursday
      time: null,
      reminder_offset_min: 0,
    },
    created_at: "2026-01-15T00:00:00Z",
    archived: false,
  },
  {
    id: "task_3",
    user_id: "usr_1",
    title: "Go to sleep",
    priority: "high",
    due_date: null,
    is_recurring: true,
    recurrence: {
      frequency: "daily",
      days_of_week: null,
      time: "22:00",
      reminder_offset_min: 30, // notify at 9:30 PM
    },
    created_at: "2026-01-20T00:00:00Z",
    archived: false,
  },

  // Backlog items
  {
    id: "task_10",
    user_id: "usr_1",
    title: "File quarterly taxes",
    priority: "high",
    due_date: "2026-02-10",
    is_recurring: false,
    recurrence: null,
    created_at: "2026-01-20T00:00:00Z",
    archived: false,
  },
  {
    id: "task_11",
    user_id: "usr_1",
    title: "Car registration renewal",
    priority: "medium",
    due_date: "2026-02-19",
    is_recurring: false,
    recurrence: null,
    created_at: "2026-01-25T00:00:00Z",
    archived: false,
  },
  {
    id: "task_12",
    user_id: "usr_1",
    title: "Schedule oil change",
    priority: "medium",
    due_date: null,
    is_recurring: false,
    recurrence: null,
    created_at: "2026-02-01T00:00:00Z",
    archived: false,
  },
  {
    id: "task_13",
    user_id: "usr_1",
    title: "Clean out garage",
    priority: "low",
    due_date: null,
    is_recurring: false,
    recurrence: null,
    created_at: "2026-02-03T00:00:00Z",
    archived: false,
  },
];

const exampleDailyTasks: DailyTask[] = [
  // Auto-generated from recurring
  {
    id: "dt_1",
    user_id: "usr_1",
    date: "2026-02-07",
    source: "recurring",
    task_id: "task_1",
    title: "Morning meditation",
    priority: "high",
    time: "07:00",
    reminder_offset_min: 0,
    status: "completed",
    completed_at: "2026-02-07T07:15:00Z",
    review_outcome: null,
    sort_order: 0,
  },
  {
    id: "dt_2",
    user_id: "usr_1",
    date: "2026-02-07",
    source: "recurring",
    task_id: "task_2",
    title: "Take out trash",
    priority: "medium",
    time: null,
    reminder_offset_min: 0,
    status: "completed",
    completed_at: "2026-02-07T08:30:00Z",
    review_outcome: null,
    sort_order: 1,
  },
  {
    id: "dt_3",
    user_id: "usr_1",
    date: "2026-02-07",
    source: "recurring",
    task_id: "task_3",
    title: "Go to sleep",
    priority: "high",
    time: "22:00",
    reminder_offset_min: 30,
    status: "pending",
    completed_at: null,
    review_outcome: null,
    sort_order: 6,
  },

  // Pulled from backlog during morning planning
  {
    id: "dt_4",
    user_id: "usr_1",
    date: "2026-02-07",
    source: "backlog",
    task_id: "task_10",
    title: "File quarterly taxes",
    priority: "high",
    time: null,
    reminder_offset_min: 0,
    status: "pending",
    completed_at: null,
    review_outcome: null,
    sort_order: 2,
  },

  // Custom one-off added during planning
  {
    id: "dt_5",
    user_id: "usr_1",
    date: "2026-02-07",
    source: "custom",
    task_id: null,
    title: "Dentist appointment",
    priority: "medium",
    time: "14:30",
    reminder_offset_min: 30,
    status: "pending",
    completed_at: null,
    review_outcome: null,
    sort_order: 3,
  },
  {
    id: "dt_6",
    user_id: "usr_1",
    date: "2026-02-07",
    source: "custom",
    task_id: null,
    title: "Reply to landlord",
    priority: "low",
    time: null,
    reminder_offset_min: 0,
    status: "completed",
    completed_at: "2026-02-07T11:45:00Z",
    review_outcome: null,
    sort_order: 4,
  },
];

// ===========================================
// Key queries the UI needs
// ===========================================
//
// TODAY SCREEN
//   Top 3:  DailyTask WHERE date=today AND status=pending ORDER BY priority DESC, sort_order LIMIT 3
//   Rest:   ...same query, OFFSET 3 (behind "N more items" button)
//   Done:   DailyTask WHERE date=today AND status=completed
//   Ring:   COUNT(*) and COUNT(status=completed) WHERE date=today
//
// MORNING PLANNING
//   Recurring: Task WHERE is_recurring=true → check recurrence.days_of_week against today
//   Upcoming:  Task WHERE due_date BETWEEN today AND today+14 ORDER BY due_date
//
// BACKLOG
//   All:       Task WHERE is_recurring=false AND archived=false ORDER BY due_date NULLS LAST
//   Due soon:  ...add WHERE due_date IS NOT NULL AND due_date <= today+14
//
// WIDGET
//   Same as Today top 3 + progress count
//
// NOTIFICATIONS (scheduled jobs)
//   Morning:   fire at user.morning_notification_time
//   Per-task:  DailyTask WHERE date=today AND time IS NOT NULL → schedule at (time - reminder_offset_min)
//   Due dates: Task WHERE due_date = today+3 OR due_date = today+1 (configurable)
//
// END OF DAY
//   Unfinished: DailyTask WHERE date=today AND status=pending
//   On review:
//     "→ Tomorrow" → create new DailyTask with date=tomorrow, same task_id
//     "→ Backlog"  → no action needed (Task still exists in backlog)
//     "Drop"       → set review_outcome=dropped, done
//   Auto-roll (no review): same as "→ Tomorrow" for all pending
//
// ===========================================
