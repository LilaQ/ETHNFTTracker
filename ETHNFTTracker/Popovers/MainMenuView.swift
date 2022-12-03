//
//  MainMenuView.swift
//  longAPStatusOSX
//
//  Created by Jan Sallads on 27.06.21.
//

import SwiftUI
import Combine

//  necessary extension for TextEditor hacks background color
extension NSTextView {
    open override var frame: CGRect {
        didSet {
            backgroundColor = .clear //<<here clear
            drawsBackground = true
        }
    }
}

struct MainMenuView: View {
    //  MARK:   AppStorage is designed to be in View, so never cross-read it, but just put it in the View where it's used!!!
    @AppStorage("wallets") var wallets: [String] = []
    @AppStorage("hiddenCollections") var hiddenCollection: [String] = []
    @State var selected: Set<String> = Set<String>()
    @State var newWallet: String = ""
    var statusBarController: StatusBarController
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("WALLETS:")
                .padding(.top, 10)
                .font(.callout)
                .foregroundColor(Color.gray)
            VStack {
                ForEach(Array(Set(wallets)).filter({ !$0.isEmpty }).sorted(), id: \.self) { wallet in
                    HStack {
                        Text(wallet)
                            .onTapGesture {
                                NSPasteboard.general.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
                                NSPasteboard.general.setString(wallet, forType: .string)
                            }
                        Spacer()
                        Image(systemName: "minus.circle.fill")
                            .onTapGesture {
                                wallets.removeAll(where: { $0 == wallet })
                                UserDefaults.standard.set(wallets, forKey: "wwwallets")
                            }
                    }
                }
            }
            HStack {
                TextField("Add new wallet", text: $newWallet)
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .onTapGesture {
                        if !newWallet.isEmpty {
                            wallets.append(newWallet)
                            UserDefaults.standard.set(wallets, forKey: "wwwallets")
                            newWallet.removeAll()
                        }
                    }
            }
            
            Divider()
                .padding(.vertical, 10)
            
            Text("Hidden Collections")
                .padding(.top, 10)
                .font(.callout)
                .foregroundColor(Color.gray)
            ScrollView {
                VStack {
                    ForEach(hiddenCollection, id: \.self) { collectionAddress in
                        HStack {
                            Text(collectionAddress)
                            Spacer()
                            Image(systemName: "minus.circle.fill")
                                .onTapGesture {
                                    hiddenCollection.removeAll(where: { $0 == collectionAddress })
                                }
                        }
                    }
                }
            }
            .frame(minHeight: 150)
            .background(.red)
            
            Divider()
                .padding(.vertical, 10)
            
            HStack {
                Spacer()
                Button("Quit") {
                    exit(0)
                }
                .background(Color.red)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
