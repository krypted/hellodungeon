//
//  RandomMapView.swift
//  RandomMapGenerator
//
//

import UIKit

typealias MapPoint = (column: Int, row: Int)
typealias MapSize = (columns: Int, rows: Int)

class RandomMapView: UIView {
    
    private var columns: Int = 0
    private var rows: Int = 0
    private var rooms: [Room] = []
    private var waysArray: [[Bool]] = []
    private var mapActiveCellCount = 0
    private var corridor: Corridor = Corridor(ways: [])
    private var blocks: [WayBlock] = []
    private var pairs: [(Room, Room, Orientation)] = []
    
    private var cellWidth: CGFloat = 10.0
    
    func generate() -> Bool {
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        columns = 0
        rows = 0
        rooms = []
        waysArray = []
        mapActiveCellCount = 0
        corridor = Corridor(ways: [])
        blocks = []
        pairs = []
        
        let minCellWidth = 5
        let maxCellWidth = self.bounds.width / 10
        
        cellWidth = CGFloat(Int.random(in: minCellWidth..<Int(maxCellWidth)))
        columns = Int(floor(bounds.width / cellWidth))
        rows = Int(floor((bounds.height) / cellWidth))
        
        for _ in 0..<rows {
            waysArray.append([Bool](repeating: false, count: columns))
        }
        
        makeCorridors()
        make()
        if rooms.count == 0 { return false }
        checkInactiveRooms()
        connectInactiveRooms()
        
        for room in rooms.filter({ (r) -> Bool in
            !r.active
        }) {
            let roomLayer = CAShapeLayer()
            let roomPath = UIBezierPath()
            drawRoom(in: roomPath, room: room)
            roomPath.stroke()
            roomPath.fill()
            roomLayer.backgroundColor = UIColor.gray.cgColor
            roomLayer.fillColor = UIColor.darkGray.cgColor
            roomLayer.path = roomPath.cgPath
            
            layer.addSublayer(roomLayer)
        }
        
        for room in rooms.filter({ (r) -> Bool in
            r.active
        }) {
            let roomLayer = CAShapeLayer()
            let roomPath = UIBezierPath()
            drawRoom(in: roomPath, room: room)
            roomPath.stroke()
            roomPath.fill()
            roomLayer.backgroundColor = UIColor.gray.cgColor
            roomLayer.fillColor = UIColor.gray.cgColor
            roomLayer.path = roomPath.cgPath
            
            layer.addSublayer(roomLayer)
        }
        
        
        for block in blocks {
            let corridorLayer = CAShapeLayer()
            let corridorPath = UIBezierPath()
            drawCorridor(in: corridorPath, block: block)
            corridorPath.stroke()
            corridorPath.fill()
            corridorLayer.backgroundColor = UIColor.clear.cgColor
            corridorLayer.fillColor = UIColor.gray.cgColor
            corridorLayer.path = corridorPath.cgPath
            
            layer.addSublayer(corridorLayer)
        }
        
        let mapLayer = CAShapeLayer()
        let blackPath = UIBezierPath()
        
        for c in 0..<columns {
            blackPath.move(to: makeCGPoint(with: MapPoint(column: c, row: 0)))
            blackPath.addLine(to: makeCGPoint(with: MapPoint(column: c, row: rows)))
        }
        blackPath.move(to: CGPoint(x: self.bounds.width - 3, y: 0))
        blackPath.move(to: CGPoint(x: self.bounds.width - 3, y: self.bounds.height))
        for r in 0..<rows {
            blackPath.move(to: makeCGPoint(with: MapPoint(column: 0, row: r)))
            blackPath.addLine(to: makeCGPoint(with: MapPoint(column: columns, row: r)))
        }
        blackPath.move(to: CGPoint(x: 0, y: self.bounds.height - 3))
        blackPath.move(to: CGPoint(x: self.bounds.width, y: self.bounds.height - 3))
        
        blackPath.stroke()
        blackPath.lineWidth = 3.0
        mapLayer.strokeColor = UIColor.black.cgColor
        mapLayer.path = blackPath.cgPath
        
        layer.addSublayer(mapLayer)
        
        
        addIndexes()
        
        return true
    }
    
//    @objc func stop() {
//        print("")
//    }
   
    
    private func addIndexes() {
        for (index, room) in rooms.enumerated() {
            let label = CATextLayer()
            label.string = "\(index)"
            label.frame = CGRect(x: makeCGFloat(with: room.point.column),
                                 y: makeCGFloat(with: room.point.row),
                                 width: makeCGFloat(with: room.point.column + room.size.columns),
                                 height: makeCGFloat(with: room.point.row + room.size.rows))
            label.fontSize = 12
            layer.addSublayer(label)
        }
    }
    
    private func drawRoom(in path: UIBezierPath, room: Room) {
        let roomPoints = [makeCGPoint(with: room.point),
                          CGPoint(x: makeCGFloat(with: room.minColumn), y: makeCGFloat(with: room.maxRow)),
                          CGPoint(x: makeCGFloat(with: room.maxColumn), y: makeCGFloat(with: room.maxRow)),
                          CGPoint(x: makeCGFloat(with: room.maxColumn), y: makeCGFloat(with: room.minRow))]
        
        path.move(to: roomPoints[0])
        path.addLine(to: roomPoints[1])
        path.addLine(to: roomPoints[2])
        path.addLine(to: roomPoints[3])
        path.addLine(to: roomPoints[0])
    }
    
    private func drawCorridor(in path: UIBezierPath, block: WayBlock) {
        
        let blockPoints = [makeCGPoint(with: block.point),
                           CGPoint(x: makeCGFloat(with: block.point.column), y: makeCGFloat(with: 1 + block.point.row)),
                           CGPoint(x: makeCGFloat(with: 1 + block.point.column), y: makeCGFloat(with: 1 + block.point.row)),
                           CGPoint(x: makeCGFloat(with: 1 + block.point.column), y: makeCGFloat(with: block.point.row))]
        
        path.move(to: blockPoints[0])
        path.addLine(to: blockPoints[1])
        path.addLine(to: blockPoints[2])
        path.addLine(to: blockPoints[3])
        path.addLine(to: blockPoints[0])
        
    }
    
    private func makeCGPoint(with point: MapPoint) -> CGPoint {
        return CGPoint(x: CGFloat(point.column) * cellWidth, y: CGFloat(point.row) * cellWidth)
    }
    
    private func makeCGFloat(with index: Int) -> CGFloat {
        return CGFloat(index) * cellWidth
    }
    
    private func make() {
        let objectsCount = columns * rows
        
        for _ in 0..<objectsCount {
            
            let width: Int = (columns-2) / 2
            let height: Int = (rows-2) / 2
            
            if width <= 4 || height <= 4 { continue }
            
            let size = MapSize(columns: Int.random(in: 4..<width), rows: Int.random(in: 4..<height))
            
            rooms.append(Room(id: UUID().uuidString, point: MapPoint(column: 0, row: 0), size: size, direction: .def))
        }
        
        var filteredRooms: [Room] = []
        
        for i in 0..<rooms.count {
            if i == 0 {
                let columnPosition = Int.random(in: 1..<columns-rooms[i].size.columns-1)
                let rowPosition = Int.random(in: 1..<rows-rooms[i].size.rows-1)
                rooms[i].point = MapPoint(column: columnPosition, row: rowPosition)
                filteredRooms.append(rooms[i])
            } else {
                let columnPosition = Int.random(in: 1..<columns-rooms[i].size.columns-1)
                let rowPosition = Int.random(in: 1..<rows-rooms[i].size.rows-1)
                rooms[i].point = MapPoint(column: columnPosition, row: rowPosition)
                
                var room = rooms[i]
                
                let res = filteredRooms.filter { (rm) -> Bool in
                    let minColumn = room.minColumn
                    let maxColumn = room.maxColumn
                    let minRow = room.minRow
                    let maxRow = room.maxRow
                    
                    let minRoomColumn = rm.minColumn
                    let maxRoomColumn = rm.maxColumn
                    let minRoomRow = rm.minRow
                    let maxRoomRow = rm.maxRow
                    
                    let res = (minRow...maxRow).overlaps(minRoomRow...maxRoomRow) &&
                        (minColumn...maxColumn).overlaps(minRoomColumn...maxRoomColumn)
                    
                    return res
                }
                
                if res.count == 0 {
                    room.id = UUID().uuidString
                    filteredRooms.append(room)
                }
                
            }
            
        }
        
        filteredRooms.forEach { (room) in
            for r in room.point.row..<room.point.row+room.size.rows {
                for c in room.point.column..<room.point.column+room.size.columns {
                    waysArray[r][c] = true
                }
            }
        }
        
        rooms = filteredRooms
    }
    
    private func makeCorridors() {
        
        let allArea = columns * rows
        var wayBlocks: [WayBlock] = []
        
        let wayAreaPercent = CGFloat.random(in: 0.7..<0.8)
        let wayBlocksCount = Int(CGFloat(allArea) * wayAreaPercent)
        
        let randomStartColumn = Int.random(in: 0..<columns)
        let randomStartRow = Int.random(in: 0..<rows)
        
        let firstWayBlock = WayBlock(point: MapPoint(column: randomStartColumn, row: randomStartRow))
        wayBlocks.append(firstWayBlock)
        waysArray[randomStartRow][randomStartColumn] = true
        
        var direction = Int(CGFloat.random(in: 0..<49) / 10.0)
        
        for _ in 1..<wayBlocksCount {
            let lastBlock = wayBlocks.last
            
            var newBlockColumn = 0
            var newBlockRow = 0
            
            var notValide = true
            var directionsChecker: [Int] = [0, 0, 0, 0]
            var needToAdd = true
            
            while notValide {
                let change = Int.random(in: 0..<101) > 50
                if change {
                    direction = Int(CGFloat.random(in: 0..<49) / 10.0)
                }
                var emptySpace = false
                switch direction {
                // left
                case 0:
                    newBlockColumn = (lastBlock?.point.column)! - 1
                    newBlockRow = (lastBlock?.point.row)!
                    if newBlockColumn <= 0 || newBlockRow <= 0 || newBlockColumn >= columns-1 || newBlockRow >= rows-1 {
                        emptySpace = false
                    } else {
                        emptySpace = !(waysArray[newBlockRow][newBlockColumn] ||
                                        waysArray[newBlockRow][newBlockColumn-1] ||
                                        waysArray[newBlockRow-1][newBlockColumn-1] ||
                                        waysArray[newBlockRow-1][newBlockColumn] ||
                                        waysArray[newBlockRow+1][newBlockColumn] ||
                                        waysArray[newBlockRow+1][newBlockColumn-1])
                    }
                // top
                case 1:
                    newBlockColumn = (lastBlock?.point.column)!
                    newBlockRow = (lastBlock?.point.row)! - 1
                    if newBlockColumn <= 0 || newBlockRow <= 0 || newBlockColumn >= columns-1 || newBlockRow >= rows-1 {
                        emptySpace = false
                    } else {
                        emptySpace = !(waysArray[newBlockRow][newBlockColumn] ||
                                        waysArray[newBlockRow][newBlockColumn-1] ||
                                        waysArray[newBlockRow-1][newBlockColumn-1] ||
                                        waysArray[newBlockRow-1][newBlockColumn] ||
                                        waysArray[newBlockRow-1][newBlockColumn+1] ||
                                        waysArray[newBlockRow][newBlockColumn+1])
                    }
                // right
                case 2:
                    newBlockColumn = (lastBlock?.point.column)! + 1
                    newBlockRow = (lastBlock?.point.row)!
                    if newBlockColumn <= 0 || newBlockRow <= 0 || newBlockColumn >= columns-1 || newBlockRow >= rows-1 {
                        emptySpace = false
                    } else {
                        emptySpace = !(waysArray[newBlockRow][newBlockColumn] ||
                                        waysArray[newBlockRow-1][newBlockColumn] ||
                                        waysArray[newBlockRow-1][newBlockColumn+1] ||
                                        waysArray[newBlockRow][newBlockColumn+1] ||
                                        waysArray[newBlockRow+1][newBlockColumn+1] ||
                                        waysArray[newBlockRow+1][newBlockColumn])
                    }
                // bottom
                case 3:
                    newBlockColumn = (lastBlock?.point.column)!
                    newBlockRow = (lastBlock?.point.row)! + 1
                    if newBlockColumn <= 0 || newBlockRow <= 0 || newBlockColumn >= columns-1 || newBlockRow >= rows-1 {
                        emptySpace = false
                    } else {
                        emptySpace = !(waysArray[newBlockRow][newBlockColumn] ||
                                        waysArray[newBlockRow][newBlockColumn-1] ||
                                        waysArray[newBlockRow][newBlockColumn+1] ||
                                        waysArray[newBlockRow+1][newBlockColumn+1] ||
                                        waysArray[newBlockRow+1][newBlockColumn] ||
                                        waysArray[newBlockRow+1][newBlockColumn-1])
                    }
                default:
                    continue
                }
                
                
                notValide = !((newBlockRow >= 0) && (newBlockRow <= rows) && (newBlockColumn >= 0) && (newBlockColumn <= columns) &&
                                (emptySpace))
                if notValide {
                    directionsChecker[direction] += 1
                    if (directionsChecker[0] != 0) && (directionsChecker[1] != 0) && (directionsChecker[2] != 0) && (directionsChecker[3] != 0) {
                        needToAdd = false
                        break
                    }
                } else {
                    waysArray[newBlockRow][newBlockColumn] = true
                }
            }
            if needToAdd {
                wayBlocks.append(WayBlock(point: MapPoint(column: newBlockColumn, row: newBlockRow)))
            }
        }
        
        blocks = wayBlocks
        
    }
    
    private func checkInactiveRooms() {
        for i in 0..<rooms.count {
            //left check
            for r in rooms[i].minRow..<rooms[i].maxRow {
                let column = rooms[i].minColumn - 1
                if column < 0 { break }
                if waysArray[r][column] {
                    rooms[i].active = true
                    rooms[i].direction = .left
                    break
                }
            }
            
            //right check
            for r in rooms[i].minRow..<rooms[i].maxRow {
                let column = rooms[i].maxColumn
                if column >= columns-1 { break }
                if waysArray[r][column] {
                    rooms[i].active = true
                    rooms[i].direction = .right
                    break
                }
            }
            
            //top check
            for c in rooms[i].minColumn..<rooms[i].maxColumn {
                let row = rooms[i].minRow - 1
                if row < 0 { break }
                if waysArray[row][c] {
                    rooms[i].active = true
                    rooms[i].direction = .up
                    break
                }
            }
            
            //bottom check
            for c in rooms[i].minColumn..<rooms[i].maxColumn {
                let row = rooms[i].maxRow
                if row >= rows-1 { break }
                if waysArray[row][c] {
                    rooms[i].active = true
                    rooms[i].direction = .down
                    break
                }
            }
        }
        printWayArray()
        print("")
    }
    
    private func connectInactiveRooms() {
        
        while !isAllRoomsActive() {
            let inactiveRooms = rooms.filter({ !$0.active })
            let randomInactiveRoomIndex = Int.random(in: 0..<inactiveRooms.count)
            let room = inactiveRooms[randomInactiveRoomIndex]
            
            let isHorizontalMove = Bool.random()
            
            if isHorizontalMove {
                let horizontalMoveRooms = rooms.filter { (filterRoom) -> Bool in
                    return (room.id != filterRoom.id) && (room.minRow..<room.maxRow).overlaps(filterRoom.minRow..<filterRoom.maxRow)
                }
                
                if let finalRoom = horizontalMoveRooms.randomElement() {
                    let from = room.minRow > finalRoom.minRow ? room.minRow : finalRoom.minRow
                    let to = room.maxRow < finalRoom.maxRow ? room.maxRow : finalRoom.maxRow
                    
                    let columnStart = room.minColumn < finalRoom.minColumn ? room.minColumn : finalRoom.minColumn
                    let columnFinal = room.minColumn > finalRoom.minColumn ? room.minColumn : finalRoom.minColumn
                    
                    let row = Int.random(in: from...to)
                    
                    for i in columnStart...columnFinal {
                        blocks.append(WayBlock(point: MapPoint(column: i, row: row)))
                        waysArray[row][i] = true
                    }
                    
                    for i in 0..<rooms.count {
                        if rooms[i].id == room.id {
                            rooms[i].active = true
                        }
                        if rooms[i].id == finalRoom.id {
                            rooms[i].active = true
                        }
                    }
                    pairs.append((room, finalRoom, .horizontal))
                }
                
            } else {
                let verticalMoveRooms = rooms.filter { (filterRoom) -> Bool in
                    return (room.id != filterRoom.id) && (room.minColumn..<(room.maxColumn)).overlaps(filterRoom.minColumn..<(filterRoom.maxColumn))
                }
                if let finalRoom = verticalMoveRooms.randomElement() {
                    let from = room.minColumn > finalRoom.minColumn ? room.minColumn : finalRoom.minColumn
                    let to = room.maxColumn < finalRoom.maxColumn ? room.maxColumn : finalRoom.maxColumn
                    
                    let column = Int.random(in: from...to)
                    
                    let rowStart = room.minRow < finalRoom.minRow ? room.minRow : finalRoom.minRow
                    let rowFinal = room.minRow > finalRoom.minRow ? room.minRow : finalRoom.minRow
                    
                    for i in rowStart...rowFinal {
                        blocks.append(WayBlock(point: MapPoint(column: column, row: i)))
                        waysArray[i][column] = true
                    }
                    
                    for i in 0..<rooms.count {
                        if rooms[i].id == room.id {
                            rooms[i].active = true
                            rooms[i].connectedRooms.append((finalRoom, .vertical))
                        }
                        if rooms[i].id == finalRoom.id {
                            rooms[i].active = true
                            rooms[i].connectedRooms.append((finalRoom, .vertical))
                        }
                    }
                    pairs.append((room, finalRoom, .vertical))
                }
            }
        }
    }
    
    private func isAllRoomsActive() -> Bool {
        return rooms.filter({ !$0.active }).count == 0
    }
    
    enum MapObject {
        case empty
        case room
        case corridor
        case wall
    }
    
    private func drawRect(path: UIBezierPath, x: CGFloat, y: CGFloat) {
        path.move(to: CGPoint(x: x, y: y))
        path.addLine(to: CGPoint(x: x, y: y+cellWidth))
        path.addLine(to: CGPoint(x: x+cellWidth, y: y+cellWidth))
        path.addLine(to: CGPoint(x: x+cellWidth, y: y))
        path.addLine(to: CGPoint(x: x, y: y))
    }
    
    private func printWayArray() {
        let arr = waysArray.map { (line) -> [Int] in
            line.map { (val) -> Int in
                return val ? 0 : 1
            }
        }
        for i in 0..<arr.count {
            print(arr[i])
        }
    }
    
}

struct Room {
    var id: String
    var point: MapPoint
    var size: MapSize
    var active = false
    var direction: Direction
    var connectedRooms: [(Room, Orientation)] = []
    
    var minColumn: Int {
        return point.column
    }
    
    var maxColumn: Int {
        return point.column + size.columns
    }
    
    var minRow: Int {
        return point.row
    }
    
    var maxRow: Int {
        return point.row + size.rows
    }
}

struct Corridor {
    var ways: [CorridorBlock]
}

struct CorridorBlock {
    var point: MapPoint
    var length: Int
    var orientation: Orientation
}

struct WayBlock {
    var point: MapPoint
    
}

enum Orientation {
    case vertical
    case horizontal
}

enum Direction {
    case up
    case down
    case left
    case right
    case def
}

extension UIColor {
    static func random() -> UIColor {
        return UIColor(
            red:   .random(),
            green: .random(),
            blue:  .random(),
            alpha: 1.0
        )
    }
}

extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}
