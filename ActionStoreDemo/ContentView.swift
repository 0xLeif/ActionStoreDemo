//
//  ContentView.swift
//  ActionStoreDemo
//
//  Created by 0x on 5/17/22.
//

import CacheStore
import Combine
import SwiftUI

enum ContentStoreKey {
    case title
    
    case task
}

enum ContentStoreAction {
    case onInit
    
    case titleUpdated(String)
}

let contentStoreActionHandler = StoreActionHandler<ContentStoreKey, ContentStoreAction, Void> { store, action, _ in
    switch action {
    case .onInit:
        store.get(.task, as: AnyCancellable.self)?.cancel()
        store.set(
            value: store
                .publisher
                .compactMap { $0.get(.title, as: String.self) }
                .removeDuplicates()
                .sink { title in
                    print("New Title: \(title)")
                },
            forKey: .task
        )
        
    case let .titleUpdated(title):
        store.set(value: title, forKey: .title)
    }
}


struct ContentView: View {
    @ObservedObject var store: Store<ContentStoreKey, ContentStoreAction, Void>
     
    init(store: Store<ContentStoreKey, ContentStoreAction, Void>) {
        self._store = ObservedObject(initialValue: store)
        self.store.handle(action: .onInit)
    }
    
    var body: some View {
        TextField("Title", text: store.binding(.title, using: ContentStoreAction.titleUpdated))
            .navigationTitle(Text(store.resolve(.title, as: String.self)))
    }
}
