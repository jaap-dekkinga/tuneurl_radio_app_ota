import SwiftUI
import TuneURL

struct EngagementSheetModifier: ViewModifier {
    
    @State var state = StateManager.shared
    
    func body(content: Content) -> some View {
        content.sheet(item: $state.currentMatch) { match in
            EngagementScreen(
                engagement: .init(match),
                stationId: state.currentPlayingStation?.id
            )
            .withEnv()
            .presentationDetents([.fraction(0.95), .large], selection: .constant(.large))
            .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.95)))
        }
    }
}

public extension View {
    func sneet<Item, Content>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View where Item : Identifiable, Content : View {
        self.modifier(ItemOverlaySheetViewModifier(item: item, child: content))
            .onChange(of: item.wrappedValue?.id) { oldValue, newValue in
                if newValue == nil, let onDismiss = onDismiss {
                    onDismiss()
                }
            }
    }
    
    func sneet<Content>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View where Content : View {
        self.modifier(IsPresentedOverlaySheetViewModifier(isPresented: isPresented, child: content))
            .onChange(of: isPresented.wrappedValue) { oldValue, newValue in
                if newValue == false, let onDismiss = onDismiss {
                    onDismiss()
                }
            }
    }
}

struct IsPresentedOverlaySheetViewModifier<Child: View>: ViewModifier {
    @Binding var isPresented: Bool
    let child: () -> Child
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            ZStack(alignment: .bottom) {
                if isPresented {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            self.isPresented = false
                        }
                }
                
                if isPresented {
                    IsPresentedSheetContainerView(isPresented: $isPresented) {
                        child()
                    }
                    .transition(.move(edge: .bottom))
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .animation(.default, value: isPresented)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ItemOverlaySheetViewModifier<Child: View, Item: Identifiable>: ViewModifier {
    @Binding var item: Item?
    let child: (Item) -> Child
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            ZStack(alignment: .bottom) {
                if let item {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            self.item = nil
                        }
                }
                
                if let item {
                    ItemSheetContainerView(item: $item) {
                        child(item)
                    }
                    .transition(.move(edge: .bottom))
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .animation(.default, value: item?.id)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct IsPresentedSheetContainerView<Content: View>: View {
    @Binding var isPresented: Bool
    @GestureState private var dragOffset: CGFloat = .zero
    @State private var contentHeight: CGFloat = 0
    let content: () -> Content
    
    var body: some View {
        VStack {
            content()
                .background {
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear {
                                contentHeight = proxy.size.height
                            }
                    }
                }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(.rect(cornerRadii: .init(topLeading: 40, bottomLeading: 0, bottomTrailing: 0, topTrailing: 40)))
        .shadow(color: .black.opacity(0.3), radius: 16, x: 0, y: -2)
        .offset(y: dragOffset)
        .gesture(dragGesture)
    }
    
    var dragGesture: some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, transaction in
                guard value.translation.height > 0 else { return }
                state = value.translation.height
            }
            .onEnded { value in
                guard value.translation.height > 0 else { return }
                if value.translation.height > contentHeight / 2 {
                    isPresented = false
                }
            }
    }
}

struct ItemSheetContainerView<Content: View, Item: Identifiable>: View {
    @Binding var item: Item?
    @GestureState private var dragOffset: CGFloat = .zero
    @State private var contentHeight: CGFloat = 0
    let content: () -> Content
    
    var body: some View {
        VStack {
            content()
                .background {
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear {
                                contentHeight = proxy.size.height
                            }
                    }
                }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(.rect(cornerRadii: .init(topLeading: 40, topTrailing: 40)))
        .shadow(color: .black.opacity(0.3), radius: 16, x: 0, y: -2)
        .offset(y: dragOffset)
        .gesture(dragGesture)
    }
    
    var dragGesture: some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, transaction in
                guard value.translation.height > 0 else { return }
                state = value.translation.height
            }
            .onEnded { value in
                guard value.translation.height > 0 else { return }
                if value.translation.height > contentHeight / 2 {
                    item = nil
                }
            }
    }
}
