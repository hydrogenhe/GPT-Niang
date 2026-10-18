import SwiftUI

struct TaskCompletionView: View {
    let result: TaskCompletion
    let title: String
    @ObservedObject var model: WidgetModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var remaining: Double?
    @State private var trailing: Double?
    private let ink = Color(hex: "745A98")

    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 6) {
                Text(title).lineLimit(1)
                if result.stopped { Text(model.text("已停止")).fixedSize() }
            }.font(.system(size: 12, weight: .semibold))
            if let before = result.before, let after = result.after {
                HStack(spacing: 5) {
                    Text(model.text("5 小时剩余")).font(.system(size: 11))
                    Spacer(minLength: 0)
                    Text("\(percent(before))% → \(percent(after))%")
                        .font(.system(size: 14, weight: .semibold)).monospacedDigit()
                }
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(hex: "EAE4F3"))
                        Capsule().fill(Color(hex: "E5B695"))
                            .frame(width: geometry.size.width * fraction(trailing ?? before))
                        Capsule().fill(LinearGradient(colors: [Color(hex: "A789CA"), ink], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geometry.size.width * fraction(remaining ?? before))
                    }
                }.frame(height: 7)
                .accessibilityLabel(model.text("5 小时剩余"))
                .accessibilityValue("\(percent(after))%")
            }
            Text(result.tokens.map { model.text("本轮 %@ tokens", number(Double($0))) } ?? model.text("本轮 token 未记录"))
                .font(.system(size: 17, weight: .semibold)).monospacedDigit().lineLimit(1)
            if let total = result.estimatedTotal {
                Text(model.text("估算 5 小时总量 ≈ %@ tokens", number(total)))
                    .font(.system(size: 11)).lineLimit(2)
            } else {
                Text(result.estimateNote).font(.system(size: 11)).lineLimit(2)
            }
        }
        .foregroundStyle(ink).minimumScaleFactor(0.75).padding(.horizontal, 10)
        .help(details)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { model.openTaskConversation() }
        .task(id: result.after) {
            guard let before = result.before, let after = result.after else { return }
            remaining = before; trailing = before
            if reduceMotion { remaining = after; trailing = after; return }
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 1.2)) { remaining = after }
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 1.1)) { trailing = after }
        }
        .onChange(of: reduceMotion) { reduced in
            if reduced { remaining = result.after; trailing = result.after }
        }
    }

    private var details: String {
        var lines = [model.text("点击打开对应对话"), model.text("按本对话日志计算 token；总量为观测估算，并非官方额度。")]
        if let before = result.before, let after = result.after {
            lines.append(model.text("5 小时剩余") + "：\(percent(before))% → \(percent(after))%")
        }
        if let total = result.estimatedTotal { lines.append(model.text("估算 5 小时总量 ≈ %@ tokens", number(total))) }
        if let previous = result.previousEstimatedTotal { lines.append(model.text("上次估算 ≈ %@ tokens", number(previous))) }
        return lines.joined(separator: "\n")
    }
    private func fraction(_ value: Double) -> Double { max(0, min(1, value / 100)) }
    private func percent(_ value: Double) -> String {
        String(format: "%.1f", value).replacingOccurrences(of: ".0", with: "")
    }
    private func number(_ value: Double) -> String {
        NumberFormatter.localizedString(from: NSNumber(value: value.rounded()), number: .decimal)
    }
}
