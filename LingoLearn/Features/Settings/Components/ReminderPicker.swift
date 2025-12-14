//
//  ReminderPicker.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI

struct ReminderPicker: View {
    @Binding var time: Date

    var body: some View {
        HStack {
            Text("提醒时间")

            Spacer()

            DatePicker(
                "",
                selection: $time,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
        }
    }
}

#Preview {
    Form {
        ReminderPicker(time: .constant(Date()))
    }
}
