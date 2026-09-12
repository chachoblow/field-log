//
//  ContentView.swift
//  FieldLog
//
//  Created by Wesley Klein on 9/11/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \Recording.startedAt, order: .reverse) private var recordings: [Recording]

    var body: some View {
        NavigationStack {
            List(recordings) { recording in
                Text(recording.startedAt, format: .dateTime)
            }
            .navigationTitle("Recordings")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(try! ModelContainer.fieldLog(inMemory: true))
}
