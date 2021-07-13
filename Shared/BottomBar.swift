//
//  BottomBar.swift
//  RSSBud
//
//  Created by Cay Zhang on 2021/6/17.
//

import SwiftUI
import Combine
import LinkPresentation

struct BottomBar: View {
    @ObservedObject var viewModel: Self.ViewModel
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 8) {
                if state != .focusedOnLink {
                    HStack(spacing: 20) {
                        WideButton("Read From Clipboard", systemImage: "arrow.up.doc.on.clipboard", backgroundColor: UIColor.secondarySystemBackground, action: viewModel.analyzeClipboardContent)
                    }.transition(.offset(y: -50).combined(with: .scale(scale: 0.5)).combined(with: .opacity))
                }
                if state != .focusedOnControls {
                    mainCell
                        .transition(.offset(y: 50).combined(with: .scale(scale: 0.5)).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 8)
        }.padding(.horizontal, 16)
        .animation(Self.transitionAnimation, value: state)
    }
    
    @ViewBuilder var mainCell: some View {
        if let url = viewModel.linkURL {
            ZStack {
                viewModel.linkImage?
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .opacity((viewModel.progress == 1.0) ? 0.5 : 0.0)
                    .allowsHitTesting(false)
                
                Rectangle().fill(.thinMaterial).transition(.identity)
                
                AutoAdvancingProgressView(viewModel: viewModel.progressViewModel)
                    .progressViewStyle(BarProgressViewStyle())
                    .opacity((viewModel.progress != 1.0) ? 0.1 : 0.0)
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        linkTitleView
                            .font(.system(size: 15, weight: .semibold, design: .default))
                            .transition(.offset(y: -25).combined(with: .opacity))
                        
                        Text((viewModel.linkTitle != nil) ? conciseRepresentation(of: url) : detailedRepresentation(of: url))
                            .animatableFont(size: (viewModel.linkTitle != nil) ? 13 : 15, weight: (viewModel.linkTitle != nil) ? .regular : .semibold)
                            .foregroundColor((viewModel.linkTitle != nil) ? .secondary : .primary)
                    }
                    Spacer()
                    if viewModel.linkIconSize == .large {
                        viewModel.linkIcon?
                            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                            .transition(.offset(x: 25).combined(with: .opacity))
                    }
                }.padding(16)
                .font(Font.body.weight(.semibold))
                .layoutPriority(1)
            }.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .onTapGesture {
                withAnimation(BottomBar.transitionAnimation) {
                    state = (state == .expanded) ? .focusedOnLink : .expanded
                }
            }
        }
    }
    
    @ViewBuilder var linkTitleView: some View {
        if let title = viewModel.linkTitle {
            if let icon = viewModel.linkIcon, viewModel.linkIconSize == .small {
                Label { Text(title).lineLimit(1) } icon: { icon }
            } else {
                Text(title)
            }
        }
    }
    
    struct Cell<Label: View>: View {
        
        var cornerRadius: CGFloat = 8
        @ViewBuilder var label: Label
       
        var body: some View {
            HStack { label }
                .font(Font.body.weight(.semibold))
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(Rectangle().fill(.thinMaterial).transition(.identity))
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        
    }
}

extension BottomBar {
    class ViewModel: ObservableObject {
        @Published var state: ViewState = .focusedOnControls
        @Published var linkURL: URLComponents?
        @Published var linkTitle: String?
        @Published var linkIcon: Image?
        @Published var linkImage: Image?
        @Published var linkIconSize: LinkIconSize = .large
        
        @Published var progress: Double = 1.0
        let progressViewModel = AutoAdvancingProgressView.ViewModel()
        
        var analyzeClipboardContent: () -> Void = { }
        
        var cancelBag = Set<AnyCancellable>()
        
        init() {
            $progress
                .assign(to: \.progress, on: progressViewModel)
                .store(in: &cancelBag)
        }
    }
}

extension BottomBar {
    enum ViewState {
        case expanded, focusedOnControls, focusedOnLink
    }
    
    enum LinkIconSize {
        case small, large
    }
    
    var state: ViewState {
        get { viewModel.state }
        nonmutating set { viewModel.state = newValue }
    }
    
    var isExpanded: Bool {
        state == .expanded
    }
    
    func conciseRepresentation(of url: URLComponents) -> AttributedString {
        AttributedString(url.host ?? "")
    }
    
    func detailedRepresentation(of url: URLComponents) -> AttributedString {
        guard let rangeOfHost = url.rangeOfHost,
              let startingIndexOfPath = url.rangeOfPath?.lowerBound,
              let hostString = url.string?[rangeOfHost],
              let afterHostString = url.string?[startingIndexOfPath...]
        else {
            return AttributedString("")
        }
        let host = AttributedString(hostString)
        var afterHost = AttributedString(afterHostString)
        afterHost.foregroundColor = Color.secondary
        return host + afterHost
    }
}

extension BottomBar {
    static var transitionAnimation: Animation { Animation.interpolatingSpring(mass: 3, stiffness: 1000, damping: 500, initialVelocity: 0) }
    static var contentTransition: AnyTransition {
        AnyTransition.offset(y: 25).combined(with: AnyTransition.opacity)
    }
}

struct BottomBar_Previews: PreviewProvider {
    static func bottomBar(for url: URLComponents) -> BottomBar {
        let model = ContentView.ViewModel()
        model.originalURL = url
        model.bottomBarViewModel.state = .focusedOnLink
        return BottomBar(viewModel: model.bottomBarViewModel)
    }
    
    static var previews: some View {
        Group {
            bottomBar(for: "https://space.bilibili.com/17404347")
            bottomBar(for: "https://www.youtube.com/watch?v=7A5-eRfDQ0M")
        }
    }
}
