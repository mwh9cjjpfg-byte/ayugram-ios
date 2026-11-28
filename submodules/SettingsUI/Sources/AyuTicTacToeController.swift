import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramPresentationData
import AccountContext

/// Offline tic-tac-toe against a simple computer opponent. Nothing is sent anywhere.
public final class AyuTicTacToeController: ViewController {
    private let context: AccountContext
    private var presentationData: PresentationData
    private var board: [Int] = Array(repeating: 0, count: 9)
    private var finished = false
    private var buttons: [UIButton] = []
    private let statusLabel = UILabel()
    private let restartButton = UIButton(type: .system)
    private var lastLayout: ContainerViewLayout?
    
    public init(context: AccountContext) {
        self.context = context
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        self.title = "Крестики-нолики"
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Back, style: .plain, target: nil, action: nil)
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func loadDisplayNode() {
        self.displayNode = ASDisplayNode()
        self.displayNode.backgroundColor = self.presentationData.theme.list.blocksBackgroundColor
        self.displayNodeDidLoad()
        
        let view = self.displayNode.view
        self.statusLabel.textAlignment = .center
        self.statusLabel.font = UIFont.systemFont(ofSize: 20.0, weight: .semibold)
        self.statusLabel.textColor = self.presentationData.theme.list.itemPrimaryTextColor
        view.addSubview(self.statusLabel)
        
        for i in 0 ..< 9 {
            let button = UIButton(type: .custom)
            button.tag = i
            button.backgroundColor = self.presentationData.theme.list.itemBlocksBackgroundColor
            button.layer.cornerRadius = 12.0
            button.titleLabel?.font = UIFont.systemFont(ofSize: 48.0, weight: .bold)
            button.addTarget(self, action: #selector(self.cellPressed(_:)), for: .touchUpInside)
            view.addSubview(button)
            self.buttons.append(button)
        }
        
        self.restartButton.setTitle("Новая игра", for: .normal)
        self.restartButton.titleLabel?.font = UIFont.systemFont(ofSize: 18.0, weight: .medium)
        self.restartButton.addTarget(self, action: #selector(self.restartPressed), for: .touchUpInside)
        view.addSubview(self.restartButton)
        
        self.refresh()
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        self.lastLayout = layout
        
        let navigationHeight = self.navigationLayout(layout: layout).navigationFrame.maxY
        let side = min(layout.size.width - 48.0, 360.0)
        let spacing: CGFloat = 8.0
        let cell = (side - spacing * 2.0) / 3.0
        let originX = floor((layout.size.width - side) / 2.0)
        let originY = navigationHeight + 90.0
        
        self.statusLabel.frame = CGRect(x: 0.0, y: navigationHeight + 30.0, width: layout.size.width, height: 30.0)
        for i in 0 ..< 9 {
            let row = CGFloat(i / 3)
            let column = CGFloat(i % 3)
            self.buttons[i].frame = CGRect(x: originX + column * (cell + spacing), y: originY + row * (cell + spacing), width: cell, height: cell)
        }
        self.restartButton.frame = CGRect(x: 0.0, y: originY + side + 24.0, width: layout.size.width, height: 44.0)
    }
    
    private static let lines: [[Int]] = [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]]
    
    private func winner() -> Int {
        for line in AyuTicTacToeController.lines {
            let value = self.board[line[0]]
            if value != 0 && value == self.board[line[1]] && value == self.board[line[2]] {
                return value
            }
        }
        return 0
    }
    
    private func refresh() {
        for i in 0 ..< 9 {
            let value = self.board[i]
            self.buttons[i].setTitle(value == 1 ? "✕" : (value == 2 ? "◯" : ""), for: .normal)
            self.buttons[i].setTitleColor(value == 1 ? self.presentationData.theme.list.itemAccentColor : self.presentationData.theme.list.itemDestructiveColor, for: .normal)
        }
        let result = self.winner()
        if result == 1 {
            self.statusLabel.text = "Ты победил!"
            self.finished = true
        } else if result == 2 {
            self.statusLabel.text = "Победил компьютер"
            self.finished = true
        } else if !self.board.contains(0) {
            self.statusLabel.text = "Ничья"
            self.finished = true
        } else {
            self.statusLabel.text = "Твой ход (✕)"
        }
    }
    
    @objc private func cellPressed(_ button: UIButton) {
        let index = button.tag
        if self.finished || self.board[index] != 0 {
            return
        }
        self.board[index] = 1
        if self.winner() == 0, self.board.contains(0) {
            self.board[self.computerMove()] = 2
        }
        self.refresh()
    }
    
    @objc private func restartPressed() {
        self.board = Array(repeating: 0, count: 9)
        self.finished = false
        self.refresh()
    }
    
    private func computerMove() -> Int {
        // Win if possible, otherwise block, otherwise centre, corner, any.
        for player in [2, 1] {
            for line in AyuTicTacToeController.lines {
                let values = line.map { self.board[$0] }
                if values.filter({ $0 == player }).count == 2, let empty = line.first(where: { self.board[$0] == 0 }) {
                    return empty
                }
            }
        }
        if self.board[4] == 0 {
            return 4
        }
        let corners = [0, 2, 6, 8].filter { self.board[$0] == 0 }
        if let corner = corners.randomElement() {
            return corner
        }
        return (0 ..< 9).filter { self.board[$0] == 0 }.first ?? 0
    }
}
