import Foundation

enum RelativeFormatter {
    /// "2 min ago", "14 min ago", "Today", "yesterday"
    static func relativeTimestamp(from date: Date, now: Date = Date()) -> String {
        let elapsed = now.timeIntervalSince(date)
        if elapsed < 60 { return "just now" }
        if elapsed < 3600 {
            let mins = Int(elapsed / 60)
            return "\(mins) min ago"
        }
        if elapsed < 86_400 {
            let hours = Int(elapsed / 3600)
            return "\(hours)h ago"
        }
        let days = Int(elapsed / 86_400)
        return "\(days)d ago"
    }

    /// "Today", "Tomorrow", "Wed, May 14"
    static func dueLabel(from date: Date, now: Date = Date()) -> String? {
        let cal = Calendar.current
        if cal.isDateInToday(date)    { return "Today" }
        if cal.isDateInTomorrow(date) { return "Tomorrow" }
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: date)
    }

    /// "9:14 AM"
    static func clockTime(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }
}

extension SuggestionViewModel {
    init(_ suggestion: Suggestion, customers: [Customer], products: [Product], now: Date = Date()) {
        let customerName = customers.first(where: { $0.id == suggestion.customerId })?.name
        let productName = products.first(where: { $0.id == suggestion.productId })?.name
        let due = suggestion.suggestedDue.flatMap { RelativeFormatter.dueLabel(from: $0, now: now) }

        let label: String
        if let channel = suggestion.sourceChannel, !channel.isEmpty {
            label = channel
        } else {
            label = "DM"
        }

        self.init(
            id: suggestion.id,
            source: Self.guessSource(from: suggestion.sourceId),
            sourceLabel: label,
            person: suggestion.sourcePerson ?? "Unknown",
            title: suggestion.title,
            snippet: suggestion.contextSnippet,
            urgency: suggestion.urgency,
            due: due,
            customer: customerName,
            product: productName,
            receivedAt: RelativeFormatter.relativeTimestamp(from: suggestion.createdAt, now: now)
        )
    }

    private static func guessSource(from sourceId: String) -> Source.Kind {
        sourceId.hasPrefix("gmail") ? .gmail : .slack
    }
}

extension TaskViewModel {
    init(_ task: ToraTask, customers: [Customer], products: [Product], now: Date = Date()) {
        self.init(
            id: task.id,
            title: task.title,
            customer: customers.first(where: { $0.id == task.customerId })?.name,
            product: products.first(where: { $0.id == task.productId })?.name,
            priority: task.priority,
            due: task.dueDate.flatMap { RelativeFormatter.dueLabel(from: $0, now: now) },
            completed: task.completed,
            completedAt: task.completedAt.flatMap { RelativeFormatter.clockTime(from: $0) }
        )
    }
}
