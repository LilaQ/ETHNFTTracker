//
//  StatusBarController.swift
//
//  Created by Jan Sallads on 20.06.21.
//

import AppKit
import SwiftUI
import UserNotifications
import AVFoundation
import Combine

var player: AVAudioPlayer?

func tintedImage(_ image: NSImage, color: NSColor) -> NSImage {
    let newImage = NSImage(size: image.size)
    newImage.lockFocus()

    // Draw with specified transparency
    let imageRect = NSRect(origin: .zero, size: image.size)
    image.draw(in: imageRect, from: imageRect, operation: .sourceOver, fraction: color.alphaComponent)

    // Tint with color
    color.withAlphaComponent(1).set()
    imageRect.fill(using: .sourceAtop)

    newImage.unlockFocus()
    return newImage
}

class StatusBarController {
    private var statusBar: NSStatusBar
    private var mainMenuItem: NSStatusItem
    
    private var gweiText: NSStatusItem?
    private var accountBalanceText: NSStatusItem?
    private var ethPriceText: NSStatusItem?
    private var nftListText: NSStatusItem?
    private var sumListText: NSStatusItem?
    
    private var popover: NSPopover
    private var mainMenuPopover: NSPopover
    private var accountBalancePopover: NSPopover
    private var ethPricePopover: NSPopover
    private var nftListPopover: NSPopover
    
    private var nftListView: NFTListView = NFTListView()
    
    var clicked: NSStatusItem?
    
    //  styles
    let regularAttribute = [NSAttributedString.Key.font: NSFont.systemFont(ofSize: 10), .foregroundColor: NSColor.darkGray]
    let regularGreenAttribute = [NSAttributedString.Key.font: NSFont.systemFont(ofSize: 10), .foregroundColor: NSColor.darkGray]
    let regularRedAttribute = [NSAttributedString.Key.font: NSFont.systemFont(ofSize: 10), .foregroundColor: NSColor.red]
    let hiddenAttribute = [NSAttributedString.Key.font: NSFont.systemFont(ofSize: 9), .foregroundColor: NSColor.darkGray]
    let smallYellowAttribute = [NSAttributedString.Key.font: NSFont.systemFont(ofSize: 10), .foregroundColor: NSColor.yellow]
    let fatAttribute: [NSAttributedString.Key: Any] = [.foregroundColor: NSColor.black, NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: 9), NSAttributedString.Key.kern: 2]
    
    var ethPrice: Double = 0.0
    var walletsBalance: Double = 0.0
    
    var timer:Timer!
    
    init(_ popover: NSPopover) {
        self.popover = popover
        self.popover.behavior = .transient
        
        statusBar = NSStatusBar.init()
        
        // Creating popover for Main menu
        mainMenuPopover = NSPopover()
        mainMenuPopover.contentSize = NSSize(width: 480, height: 520)
        mainMenuPopover.behavior = NSPopover.Behavior.transient
        
        // Creating popover for Account Balance
        accountBalancePopover = NSPopover()
        accountBalancePopover.contentSize = NSSize(width: 420, height: 520)
        accountBalancePopover.behavior = NSPopover.Behavior.transient
        
        // Creating popover for ETH History
        ethPricePopover = NSPopover()
        ethPricePopover.contentSize = NSSize(width: 420, height: 1040)
        ethPricePopover.behavior = NSPopover.Behavior.transient
        
        // Creating popover for NFT
        nftListPopover = NSPopover()
        nftListPopover.contentSize = NSSize(width: 420, height: 1040)
        nftListPopover.behavior = NSPopover.Behavior.transient
        
        //  init status bar items
        //        mainMenuItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        mainMenuItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        mainMenuItem.length = 30
        gweiText = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        accountBalanceText = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        ethPriceText = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        nftListText = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        sumListText = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        
        //  add icons
        let iconImage = NSImage(named: "logo")
        mainMenuItem.button?.layer = .init()
        mainMenuItem.button?.layer?.contentsGravity = .resizeAspect
        mainMenuItem.button?.layer?.contents = tintedImage(iconImage!, color: NSColor.black)
        mainMenuItem.button?.wantsLayer = true
        
        //  set click handler
        if let mainBarButton = mainMenuItem.button {
            mainBarButton.attributedTitle = NSAttributedString(string: "Main Menu")
            mainBarButton.action = #selector(toggleMainMenuPopover(sender:))
            mainBarButton.target = self
        }
        if let accountBalanceButton = accountBalanceText?.button {
            accountBalanceButton.action = #selector(toggleAccountBalancePopover(sender:))
            accountBalanceButton.target = self
        }
        if let ethPriceButton = ethPriceText?.button {
            ethPriceButton.action = #selector(toggleEthPricePopover(sender:))
            ethPriceButton.target = self
        }
        if let nftListButton = nftListText?.button {
            nftListButton.attributedTitle = NSAttributedString(string: "NFTs")
            nftListButton.action = #selector(toggleNFTListPopover(sender:))
            nftListButton.target = self
        }
        
        timer = Timer.scheduledTimer(timeInterval: 600, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
        updateTime()
    }
    
    @objc
    func toggleMainMenuPopover(sender: AnyObject) {
        if(!mainMenuPopover.isShown) {
            showPopover(sender, popover: mainMenuPopover, view: MainMenuView(statusBarController: self))
        }
        else {
            hidePopover(sender, popover: mainMenuPopover)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    @objc
    func toggleAccountBalancePopover(sender: AnyObject) {
        if(!accountBalancePopover.isShown) {
            showPopover(sender, popover: accountBalancePopover, view: MainMenuView(statusBarController: self))
        }
        else {
            hidePopover(sender, popover: accountBalancePopover)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    @objc
    func toggleEthPricePopover(sender: AnyObject) {
        if(!ethPricePopover.isShown) {
            showPopover(sender, popover: ethPricePopover, view: EthPriceHistoryView())
        }
        else {
            hidePopover(sender, popover: ethPricePopover)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    @objc
    func toggleNFTListPopover(sender: AnyObject) {
        if(!nftListPopover.isShown) {
            showPopover(sender, popover: nftListPopover, view: nftListView)
        }
        else {
            hidePopover(sender, popover: nftListPopover)
//            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    private func showPopover(_ sender: AnyObject, popover: NSPopover, view: some View) {
        popover.contentViewController = NSHostingController(rootView: view)
        popover.show(relativeTo: sender.bounds, of: sender as! NSView, preferredEdge: NSRectEdge.maxY)
        popover.becomeFirstResponder()
        popover.contentViewController?.view.window?.makeKey()
    }
    
    private func hidePopover(_ sender: AnyObject, popover: NSPopover) {
        popover.performClose(sender)
    }
    
    func mouseEventHandler(_ event: NSEvent?) {
        if(popover.isShown) {
//            hidePopover(event!)
        }
    }
    
    func showGwei() {
        gweiText = statusBar.statusItem(withLength: NSStatusItem.variableLength)
//        heliumPriceStatusBarItemImg = statusBar.statusItem(withLength: NSStatusItem.variableLength)
//        heliumPriceStatusBarItemImg?.length = 30
//        heliumPriceStatusBarItemImg?.button?.image = NSImage(systemSymbolName: "arrow.right",
//                                                             accessibilityDescription: nil)?.tint(color: NSColor.gray)
        
        //  add button functionality to gwei-text
        if let gweiButton = gweiText?.button {
            gweiButton.attributedTitle = NSAttributedString(string: "Gwei", attributes: regularAttribute)
//            gweiButton.action = #selector(toggleGweiPrice(sender:))
            gweiButton.target = self
        }
    }
    
    func hideGwei() {
        gweiText?.statusBar?.removeStatusItem(gweiText!)
//        heliumPriceStatusBarItemImg?.statusBar?.removeStatusItem(heliumPriceStatusBarItemImg!)
        gweiText = nil
//        heliumPriceStatusBarItemImg = nil
    }
    
    func loadAccountBalance(_ addresses: [String]) {
        var s: Double = 0.0
        let queue = DispatchGroup()
        addresses.forEach { wallet in
            queue.enter()
            EtherscanAPI.loadAccountBalance(address: wallet) { result in
                switch result {
                case .success(let success):
                    guard let value = Double(success.result)?.asWei else { return }
                    s += value
                case .failure(let failure):
                    print("Error while retrieving account balance: \(failure.localizedDescription)")
                }
                queue.leave()
            }
        }
        
        queue.notify(queue: .global()) {
            self.setAccountBalanceText(String(format: "%.4f", s), String(format: "%.2f", s * self.ethPrice))
            self.walletsBalance = s
        }
    }
    
    func loadGwei() {
        EtherscanAPI.loadGwei() { result in
            switch result {
            case .success(let success):
                self.setGweiText(success.result.SafeGasPrice)
            case .failure(let failure):
                print("Error while retrieving account balance: \(failure.localizedDescription)")
            }
        }
    }
    
    func loadEthPrice() {
        EtherscanAPI.loadEthPrice() { result in
            switch result {
            case .success(let success):
                let price = Double(success.result.ethusd) ?? 0.0
                let tendency: Tendency = price > self.ethPrice ? .UP : price == self.ethPrice ? .NONE : .DOWN
                self.ethPrice = price
                self.setEthPriceText(success.result.ethusd, tendency: tendency)
            case .failure(let failure):
                print("Error while retrieving account balance: \(failure.localizedDescription)")
            }
        }
    }
    
    func loadEthHistoryPrice() {
        //  daily
        CryptoCompareAPI.loadEthPriceHistory() { result in
            switch result {
            case .success(let success):
                success.Data.Data.forEach {
                    Env.shared.EthPriceHistoryDaily.push($0.close)
                }
            case .failure(let failure):
                print("Error while retrieving daily eth price history: \(failure)")
            }
        }
        
        //  hourly
        CryptoCompareAPI.loadEthPriceHistory(timing: .HOURLY) { result in
            switch result {
            case .success(let success):
                success.Data.Data.forEach {
                    Env.shared.EthPriceHistoryMinutes.push($0.close)
                }
            case .failure(let failure):
                print("Error while retrieving hourly eth price history: \(failure)")
            }
        }
    }
    
    func loadNFTs(address: String) async {
        await AlchemyAPI.loadNfts(address: address) { result in
            switch result {
            case .success(let success):
                Env.shared.NFTs[address] = success
            case .failure(_):
                print("Error while retrieving account balance")
            }
        }
        
        setNFTText(Env.shared.collectionValue)
    }
    
    func loadFloorPrices() async {
        let allNfts = Array(Env.shared.NFTs.reduce(into: [AlchemyNFTsResult.AlchemyNFTsOwnedNftsResult](), { $0.append(contentsOf: $1.value.ownedNfts) }))
        let allContracts = Set(allNfts.map({ $0.contract.address }) )
        
        var sum: Double = 0.0
        
        for contract in allContracts {
            await AlchemyAPI.loadFloorPrice(contractAddress: contract) { result in
                switch result {
                case .success(let success):
                    var p = (success.openSea.floorPrice ?? 0.0) + (success.openSea.floorPrice ?? 0.0)
                    p /= max(Double((success.openSea.floorPrice != nil ? 1 : 0) + (success.looksRare.floorPrice != nil ? 1 : 0)), 1.0)
                    Env.shared.floorPrices[contract] = p
                    if Env.shared.updateFloorPrices != nil {
                        Env.shared.updateFloorPrices!()
                    }
                    
                    //  calc collection sum for statusBar
                    let loc = Double(allNfts.filter { $0.contract.address == contract }.count) * p
                    sum += loc
                    
                case .failure(_):
                    print("Error while retrieving floor prices")
                }
            }
        }
        
        Env.shared.collectionValue = sum
        let sumValue = self.walletsBalance + sum
        self.setSumText(sumEth: sumValue, sumUsd: sumValue * self.ethPrice)
    }
    
    enum Tendency {
        case UP, DOWN, NONE
    }
    
    func setAccountBalanceText(_ s: String, _ d: String) {
        let str = NSMutableAttributedString(string: "", attributes: self.fatAttribute)
        str.append(NSAttributedString(string: "Balance: ", attributes: self.fatAttribute))
        str.append(NSAttributedString(string: "\(s) ETH / \(d) USD", attributes: self.regularAttribute))
        DispatchQueue.main.async {
            self.accountBalanceText?.button?.attributedTitle = str
        }
    }
    
    func setGweiText(_ s: String) {
        let str = NSMutableAttributedString(string: "", attributes: self.fatAttribute)
        str.append(NSAttributedString(string: "Gas: ", attributes: self.fatAttribute))
        str.append(NSAttributedString(string: "\(s) Gwei  ", attributes: self.regularAttribute))
        DispatchQueue.main.async {
            self.gweiText?.button?.attributedTitle = str
        }
    }
    
    func setEthPriceText(_ s: String, tendency: Tendency) {
        let str = NSMutableAttributedString(string: "", attributes: self.fatAttribute)
        str.append(NSAttributedString(string: "ETH: ", attributes: self.fatAttribute))
        switch tendency {
        case .UP:
            str.append(NSAttributedString(string: "$ \(s)  ", attributes: self.regularGreenAttribute))
        case .DOWN:
            str.append(NSAttributedString(string: "$ \(s)  ", attributes: self.regularRedAttribute))
        case .NONE:
            str.append(NSAttributedString(string: "$ \(s)  ", attributes: self.regularAttribute))
        }
        DispatchQueue.main.async {
            self.ethPriceText?.button?.attributedTitle = str
        }
    }
    
    func setSumText(sumEth: Double, sumUsd: Double) {
        let str = NSMutableAttributedString(string: "", attributes: self.fatAttribute)
        str.append(NSAttributedString(string: "Sum: ", attributes: self.fatAttribute))
        str.append(NSAttributedString(string: " \(String(format: "%.4f", sumEth)) ETH / \(String(format: "%.2f", sumUsd)) USD  ", attributes: self.regularAttribute))
        DispatchQueue.main.async {
            self.sumListText?.button?.attributedTitle = str
        }
    }
    
    func setNFTText(_ v: Double) {
        let str = NSMutableAttributedString(string: "", attributes: self.fatAttribute)
        str.append(NSAttributedString(string: "NFTs: ", attributes: self.fatAttribute))
        str.append(NSAttributedString(string: "\(String(format: "%.4f", v)) ", attributes: self.regularGreenAttribute))
        str.append(NSAttributedString(string: "ETH", attributes: self.regularAttribute))
        DispatchQueue.main.async {
            self.nftListText?.button?.attributedTitle = str
        }
    }
    
    func generateNotification(title: String, subtitle: String, body: String, sound: String?, image: String?) {
        let notificationCenter = UNUserNotificationCenter.current();
        notificationCenter.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                if image != nil {
                    let att = try! UNNotificationAttachment(identifier: "img", url: Bundle.main.url(forResource: image!, withExtension: "png")!)
                    content.attachments = [att]
                }
                if sound != nil {
                    self.playSound(sound!)
                }
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                notificationCenter.add(request)
            }
        }
    }
    
    func playSound(_ name: String) {
        let path = Bundle.main.path(forResource: name, ofType: "caf")!
        let url = URL(fileURLWithPath: path)
        do {
            let sound = try AVAudioPlayer(contentsOf: url)
            player = sound
            sound.play()
        } catch {
            //
        }

    }
    
    @objc func updateTime() {
        loadEthPrice()
        loadEthHistoryPrice()
        loadAccountBalance(getAllWallets())
        loadGwei()
        
        let dq = DispatchGroup()
        
        getAllWallets().forEach { wallet in
            dq.enter()
            Task {
                await loadNFTs(address: wallet)
                dq.leave()
            }
        }
        
        dq.notify(queue: .global()) {
            Task {
                await self.loadFloorPrices()
                self.setNFTText(Env.shared.collectionValue)
            }
        }
    }
    
    private func getAllWallets() -> [String] {
        let wallets = UserDefaults.standard.array(forKey: "wwwallets") as? [String]
        return wallets ?? []
    }
}

extension NSImage {
    func tint(color: NSColor) -> NSImage {
        return NSImage(size: size, flipped: false) { (rect) -> Bool in
            color.set()
            rect.fill()
            self.draw(in: rect, from: NSRect(origin: .zero, size: self.size), operation: .destinationIn, fraction: 1.0)
            return true
        }
    }
}

extension Double {
    var asWei: Double {
        self / 1000000000000000000.0
    }
}
