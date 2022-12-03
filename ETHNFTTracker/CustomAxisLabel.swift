//
//  CustomAxisLabel.swift
//  ETHNFTTracker
//
//  Created by Jan on 10.11.22.
//

import SwiftUI

public struct CustomAxisLabels<Content: View>: View {
    let axis: Axis
    let labels: [AnyView]
    
    public var body: some View {
            if self.axis == .horizontal {
                HStack(spacing: 0) {
                    ForEach(0..<self.labels.count, id: \.self) { index in
                        self.labels[index]
                        if index != self.labels.count - 1 {
                            Spacer()
                        }
                    }
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(0..<self.labels.count, id: \.self) { index in
                        self.labels[index]
                        if index != self.labels.count - 1 {
                            Spacer()
                        }
                    }
                }
            }
    }
    
    public init<Data, Label>(_ axis: Axis = .horizontal, data: Data, @ViewBuilder label: @escaping (Data.Element) -> Label) where Content == ForEach<Data, Data.Element.ID, Label>, Data : RandomAccessCollection, Label : View, Data.Element : Identifiable {
        self.axis = axis
        self.labels = data.map({ AnyView(label($0)) })
    }

    public init<Data, ID, Label>(_ axis: Axis = .horizontal, data: Data, id: KeyPath<Data.Element, ID>, @ViewBuilder label: @escaping (Data.Element) -> Label) where Content == ForEach<Data, ID, Label>, Data : RandomAccessCollection, ID : Hashable, Label : View {
        self.axis = axis
        self.labels = data.map({ AnyView(label($0)) })
    }

    public init<Label>(_ axis: Axis = .horizontal, data: Range<Int>, @ViewBuilder label: @escaping (Int) -> Label) where Content == ForEach<Range<Int>, Int, Label>, Label : View {
        self.axis = axis
        self.labels = data.map({ AnyView(label($0)) })
    }
}
