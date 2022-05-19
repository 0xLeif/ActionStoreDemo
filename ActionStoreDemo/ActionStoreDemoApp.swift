//
//  ActionStoreDemoApp.swift
//  ActionStoreDemo
//
//  Created by 0x on 5/17/22.
//

import c
import CacheStore
import SwiftUI

@main
struct ActionStoreDemoApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}

// MARK: - App Root View

enum AppStoreKey {
    // Required
    case title
    
    // Optional
    case randomValue
}

extension AppStoreKey {
    static var requiredKeys: Set<AppStoreKey> {
        [.title]
    }
}

enum AppStoreAction {
    case updateTitle(String)
    case newRandomValue
    
    case contentView(ContentStoreAction)
}

struct AppStoreDependency {
    
}

let appStoreActionHandler = StoreActionHandler<AppStoreKey, AppStoreAction, AppStoreDependency> { cacheStore, action, dependency in
    switch action {
    case let .updateTitle(title):
        cacheStore.set(value: title, forKey: .title)
        
    case .newRandomValue:
        cacheStore.set(value: Int.random(in: 0 ... 1000), forKey: .randomValue)
        
    case let .contentView(action):
        print("Log ContentView: \(action)")
    }
}

struct AppRootView: View {
    @StateObject private var store: Store<AppStoreKey, AppStoreAction, AppStoreDependency> = Store(
        initialValues: [
            .title: "Initial Title"
        ],
        actionHandler: appStoreActionHandler,
        dependency: AppStoreDependency()
    )
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                ContentView(
                    store: store.scope(
                        keyTransformation: c.transformer(
                            from: { global in
                                switch global {
                                case .title: return .title
                                default: return nil
                                }
                            },
                            to: { local in
                                switch local {
                                case .title: return .title
                                default: return nil
                                }
                            }
                        ),
                        actionHandler: contentStoreActionHandler,
                        actionTransformation: { local in
                            guard let local = local else {
                                return nil
                            }
                            return .contentView(local)
                        }
                    )
                )
                .background(Color.red)
                
                SomeRandomButtonView(
                    store: store.scope(
                        keyTransformation: c.transformer(
                            from: { global in
                                switch global {
                                case .randomValue: return .randomValue
                                default: return nil
                                }
                            },
                            to: { local in
                                switch local {
                                case .randomValue: return .randomValue
                                default: return nil
                                }
                            }
                        ),
                        actionHandler: someRandomButtonViewActionHandler
                    )
                )
                .background(Color.green)
                
                Spacer()
                
                Button("State") {
                    print(
                        dump(store)
                    )
                }
                .padding()
            }
        }
        .onAppear {
            store.handle(action: .updateTitle("On Appear!"))
        }
    }
}


// MARK: - Some Random Button

enum SomeRandomButtonKey {
    case randomValue
}

enum SomeRandomButtonAction {
    case newRandomValue
}

let someRandomButtonViewActionHandler = StoreActionHandler<SomeRandomButtonKey, SomeRandomButtonAction, Void> { store, action, _ in
    switch action {
    case .newRandomValue:
        store.set(value: Int.random(in: 0 ... 1000), forKey: .randomValue)
    }
}

struct SomeRandomButtonView: View {
    @ObservedObject var store: Store<SomeRandomButtonKey, SomeRandomButtonAction, Void>
    
    var body: some View {
        Button("Random Value: \(store.get(.randomValue, as: Int.self) ?? -1)") {
            store.handle(action: .newRandomValue)
        }
    }
}
