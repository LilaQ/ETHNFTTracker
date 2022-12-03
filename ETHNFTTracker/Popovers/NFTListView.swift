//
//  NFTListView.swift
//  ETHNFTTracker
//
//  Created by Jan on 10.11.22.
//

import SwiftUI
import CachedAsyncImage

class NFTListViewmodel: ObservableObject {
    @AppStorage("hiddenCollections") var hiddenCollections: [String] = []
    @Published var allNfts: [AlchemyNFTsResult.AlchemyNFTsOwnedNftsResult] = [AlchemyNFTsResult.AlchemyNFTsOwnedNftsResult]()
    @Published var allContracts: Set<String> = Set<String>()
    @Published var allCollections: [CollectionHeader] = []
    
    init() {
        refresh()
        Env.shared.updateFloorPrices = refresh
    }
    
    func allNftsForCollection(collectionAddress: String) -> [AlchemyNFTsResult.AlchemyNFTsOwnedNftsResult] {
        return allNfts.filter({ $0.contract.address == collectionAddress && !hiddenCollections.contains($0.contract.address) })
    }
    
    func hasCollectionStartingWithLetter(letter: String) -> Bool {
        return allCollections.contains(where: { $0.name.prefix(1) == letter })
    }
    
    func scrollIdForCollection(collection: CollectionHeader) -> String {
        let f = String(collection.name.prefix(1))
        if !f.isEmpty && Character(f).isLetter {
            return f
        }
        //  for now this is all just digits & co
        else {
            return "#"
        }
    }
    
    var collectionValue: Double {
        var sum : Double = 0.0
        allCollections.forEach { collection in
            if !hiddenCollections.contains(collection.address) {
                var collectionSum : Double = 0.0
                collectionSum = (Env.shared.floorPrices[collection.address] ?? 0.0) * Double(allNftsForCollection(collectionAddress: collection.address).count)
                sum += collectionSum
            }
        }
        Env.shared.collectionValue = sum
        return sum
    }
    
    func refresh() {
        DispatchQueue.main.async {
            self.allNfts = Array(Env.shared.NFTs.reduce(into: [AlchemyNFTsResult.AlchemyNFTsOwnedNftsResult](), { $0.append(contentsOf: $1.value.ownedNfts) }))
            self.allContracts = Set(self.allNfts.map({ $0.contract.address }) )
            
            let allCollectionAddresses = Set(self.allNfts.map({ $0.contract.address }))
            var result = [CollectionHeader]()
            allCollectionAddresses.forEach { address in
                if let col = self.allNfts.first(where: { $0.contract.address == address }) {
                    let c = CollectionHeader(name: col.contractMetadata?.name ?? "", description: col.description, imageUri: col.contractMetadata?.openSea.imageUrl ?? "", amount: self.allNfts.filter({ $0.contract.address == address }).count, address: address)
                    result.append(c)
                }
            }
            self.allCollections = result.sorted(by: { $0.name < $1.name })
            
            self.objectWillChange.send()
        }
    }
}

struct CollectionHeader: Identifiable, Hashable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var id = UUID().uuidString
    var name: String
    var description: String
    var imageUri: String
    var amount: Int
    var address: String
}

struct NFTListView: View {
    
    @State var selectedNft: AlchemyNFTsResult.AlchemyNFTsOwnedNftsResult? = nil
    @ObservedObject var viewModel: NFTListViewmodel = NFTListViewmodel()
    @State var showLargeImage: Bool = false
    @State var scrollTo: String? = nil
    
    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                
                //  quick-select alphabet
                VStack {
                    ForEach("#ABCDEFGHIJKLMNOPQRSTUVWXYZ".map { String($0) }, id: \.self) { c in
                        Text(c)
                            .frame(maxHeight: .infinity)
                            .opacity(viewModel.hasCollectionStartingWithLetter(letter: c) ? 1.0 : 0.2)
                            .onTapGesture {
                                scrollTo = c
                            }
                            .onHover { inside in
                                if inside {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                    }
                }
                .frame(width: 20)
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 10)
                
                //  scrollable NFT content
                ScrollView {
                    ScrollViewReader { reader in
                        VStack {
                            ForEach(viewModel.allCollections, id: \.self) { collection in
                                if !viewModel.hiddenCollections.contains(collection.address) {
                                    NFTCollectionheader(collectionHeader: collection, viewModel: viewModel, selectedNft: $selectedNft, showLargeImage: $showLargeImage, hideCollection: {
                                        viewModel.hiddenCollections.append(collection.address)
                                    })
                                    .id(viewModel.scrollIdForCollection(collection: collection))
                                }
                            }
                        }
                        .onChange(of: scrollTo) { val in
                            if let pos = val {
                                withAnimation {
                                    reader.scrollTo(pos, anchor: .top)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(100)
            }
            
            if showLargeImage {
                VStack {
                    VStack {
                        CachedAsyncImage(url: URL(string: selectedNft!.media.first!.gateway)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(minWidth: 80, minHeight: 80)
                            case .success(let image):
                                ZStack(alignment: .topTrailing) {
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .animation(.easeInOut(duration: 0.2))
                                        .frame(minWidth: 80, minHeight: 80)
                                        .clipped()
                                        .onTapGesture {
                                            withAnimation {
                                                self.showLargeImage = false
                                            }
                                        }
                                    Image(systemName: "doc.on.doc.fill")
                                        .padding(4)
                                        .onTapGesture {
                                            let pb = NSPasteboard.general
                                            pb.clearContents()
                                            if let u = URL(string: selectedNft!.media.first!.gateway),
                                               let nsimage = NSImage(data: try! Data(contentsOf: u)) {
                                                pb.writeObjects([nsimage])
                                            }
                                        }
                                        .onHover { inside in
                                            if inside {
                                                NSCursor.pointingHand.push()
                                            } else {
                                                NSCursor.pop()
                                            }
                                        }
                                        .background(Color.gray)
                                        .clipShape(Circle())
                                        .padding(8)
                                }
                            case .failure(let error):
                                let _ = print("Fuck: \(error.localizedDescription)")
                            @unknown default:
                                let _ = print("DoubleFuck")
                            }
                        }
                        
                        //  text
                        Text(selectedNft!.title)
                    }
                    .padding(20)
                    .background(Color(red: 0.1, green: 0.1, blue: 0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                }
                .padding(10)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.black.opacity(0.8))
                .zIndex(5000)
                .onTapGesture {
                    withAnimation {
                        self.showLargeImage = false
                    }
                }
            }
        }
        .padding(.top, 10)
        
        //  footer
        VStack(spacing: 0) {
            Divider()
            HStack {
                Text("NFT Collection (\(viewModel.allNfts.filter{ !viewModel.hiddenCollections.contains($0.contract.address) }.count) items)")
                    .font(.caption2)
                Spacer()
                HStack(spacing: 0) {
                    Text("Collection Value: ")
                        .font(.caption2)
                    Text("\(String(format: "%.4f", viewModel.collectionValue)) ")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .shadow(radius: 2.0)
                    Image("logo")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white)
                        .frame(width: 15, height: 15)
                        .padding([.vertical, .trailing], 5)
                }
            }
            .padding(.leading, 10)
        }
        .background(.blue)
    }
}

struct NFTCollectionheader: View {
    let collectionHeader: CollectionHeader
    let viewModel: NFTListViewmodel
    @State var showNfts: Bool = false
    @Binding var selectedNft: AlchemyNFTsResult.AlchemyNFTsOwnedNftsResult?
    @Binding var showLargeImage: Bool
    let hideCollection: ()->Void
    
    var body: some View {
        VStack {
            HStack(alignment: .center) {
                Text(collectionHeader.name)
                    .font(.headline)
                    .foregroundColor(.white)

                Text("( \(collectionHeader.amount)x )")
                    .font(.caption2)
                    .foregroundColor(.white)
                Spacer()

                let fp = Env.shared.floorPrices[collectionHeader.address]

                HStack(spacing: 0) {
                    Text((fp != nil) ? String(format: "FP: %.2f | ", fp!) : "FP: - | ")
                        .font(.footnote)
                    Text("Worth: ")
                        .font(.footnote)
                        .fontWeight(.bold)
                    Text((fp != nil) ? String(format: "%.2f ", fp! * Double(collectionHeader.amount)) : "-")
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }

                if let url = URL(string: collectionHeader.imageUri) {
                    CachedAsyncImage(url: url, content: { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 22, height: 22)
                                .scaleEffect(0.4)
                        case .success(let image):
                            image
                                .resizable()
                                .frame(width: 22, height: 22)
                                .scaledToFill()
                                .clipShape(RoundedRectangle(cornerRadius: 11))
                        case .failure(_):
                            Spacer()
                                .frame(width: 29, height: 22)
                        @unknown default:
                            Spacer()
                                .frame(width: 29, height: 22)
                        }
                    })
                } else {
                    Spacer()
                        .frame(width: 29, height: 22)
                }
            }
            .padding(7)
            .background(.black.opacity(0.15))
            .onTapGesture {
                withAnimation {
                    showNfts.toggle()
                }
            }
            .frame(height: 36)
            
            if showNfts {
                HStack(alignment: .top) {
                    Text(collectionHeader.description)
                        .font(.footnote)
                        .italic()
                        .onTapGesture {
                            withAnimation {
                                showNfts.toggle()
                            }
                        }
                        .padding(.horizontal, 5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                    Image(systemName: "eye.slash.fill")
                        .frame(height: 20)
                        .onTapGesture {
                            hideCollection()
                        }
                }
                .padding(.horizontal, 5)

                LazyVGrid(columns: [.init(), .init(), .init()], spacing: 5) {
                    ForEach(viewModel.allNftsForCollection(collectionAddress: collectionHeader.address), id: \.id) { nft in
                        NFTListElement(nft: nft, selectedNft: $selectedNft, showLargeImage: $showLargeImage)
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
    }
}

struct NFTListElement: View {
    
    let nft: AlchemyNFTsResult.AlchemyNFTsOwnedNftsResult
    @Binding var selectedNft: AlchemyNFTsResult.AlchemyNFTsOwnedNftsResult?
    @Binding var showLargeImage: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading) {
                if let url = URL(string: nft.media.first!.gateway) {
                    CachedAsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 80, height: 80)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .clipped()
                                .onTapGesture {
                                    selectedNft = nft
                                    withAnimation {
                                        showLargeImage = true
                                    }
                                }
                                .padding(5)
                                .background(
                                    ZStack {
                                        Color.black.opacity(0.25)
                                            .clipShape(RoundedRectangle(cornerRadius: 5))
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(lineWidth: 0.75)
                                            .foregroundColor(.white.opacity(0.3))
                                    }
                                )
                        case .failure(let error):
                            Spacer()
                                .frame(minWidth: 80, minHeight: 80)
                            let _ = print("Fuck: \(error.localizedDescription)")
                        @unknown default:
                            Spacer()
                                .frame(minWidth: 80, minHeight: 80)
                            let _ = print("DoubleFuck")
                        }
                    }
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Text(nft.title)
                            .font(.headline)
                        Spacer()
                    }
                }
                .frame(maxHeight: .infinity)
                
            }
            .padding(5)
        }
    }
}

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
