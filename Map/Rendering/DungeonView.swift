import SwiftUI

// MARK: - 3D描画ビュー(透視投影で石積みの壁・床・天井を描く)
struct DungeonView: View {
    /// 3D描画に必要なマップとプレイヤー状態を、値のまま直接受け取る。
    /// (関数ではなく値で受け取ることで、位置や向きが変わるたびに SwiftUI が再描画する)
    let map: MapData
    let player: Player

    /// 描画する最大の奥行き(マス数)。仕様書§12.5
    let maxDepth = 5

    /// 視点相対(前へd、右へi)のマスが壁か。
    /// プレイヤーの向きに合わせて、マップ上の絶対座標へ変換して調べる
    private func isWallRelative(_ d: Int, _ i: Int) -> Bool {
        map.cell(at: positionRelative(d, i)).isWall
    }

    /// 視点相対(前へd、右へi)のマスをマップ座標に変換する。
    private func positionRelative(_ d: Int, _ i: Int) -> GridPos {
        let forward = player.direction          // 前方向
        let right = forward.turnedRight         // 右方向

        let x = player.position.x
            + forward.dx * d
            + right.dx * i
        let y = player.position.y
            + forward.dy * d
            + right.dy * i

        return GridPos(x: x, y: y)
    }

    /// 深さ d のマスについて、左右どこまで調べるかと、描く順番を返す(外側 → 中央の順)。
    /// 奥へ行くほど、画面に映る横の範囲が広がる(横位置 i のマスが画面に入るのは |i| < d + 2 のとき)。
    /// そのため、奥のマスほど外側まで調べる。外側から先に描くのは、
    /// 奥の面を、手前の面で隠すため。
    private func lateralOrder(depth d: Int) -> [Int] {
        let limit = d + 1
        var order: [Int] = []
        for n in stride(from: limit, through: 1, by: -1) {
            order.append(-n)
            order.append(n)
        }
        order.append(0)
        return order
    }

    var body: some View {
        Canvas { ctx, size in
            let f = Double(size.width) / 2          // 画面の半幅。近い横壁が画面端に届く値
            let cx = Double(size.width) / 2         // 画面中央のx
            let cy = Double(size.height) / 2        // 画面中央のy

            // 3D点(X:横, Y:高さ, Z:奥行き) → 画面座標
            func project(_ x: Double, _ y: Double, _ z: Double) -> CGPoint {
                CGPoint(x: cx + f * x / z, y: cy - f * y / z)
            }

            let doorImage = ctx.resolve(Image("door"))

            func polygon(_ points: [CGPoint]) -> Path {
                var path = Path()
                guard let first = points.first else { return path }
                path.move(to: first)
                for point in points.dropFirst() { path.addLine(to: point) }
                path.closeSubpath()
                return path
            }

            func distance(_ a: CGPoint, _ b: CGPoint) -> Double {
                hypot(Double(a.x - b.x), Double(a.y - b.y))
            }

            func interpolate(_ a: CGPoint, _ b: CGPoint, _ amount: Double) -> CGPoint {
                CGPoint(
                    x: a.x + CGFloat(amount) * (b.x - a.x),
                    y: a.y + CGFloat(amount) * (b.y - a.y)
                )
            }

            /// 四隅で定義した面の中の(u, v)位置を返す。石の目地も投影面に沿わせる。
            func surfacePoint(_ u: Double, _ v: Double, corners: [CGPoint]) -> CGPoint {
                let upper = interpolate(corners[0], corners[1], u)
                let lower = interpolate(corners[3], corners[2], u)
                return interpolate(upper, lower, v)
            }

            /// 透視投影した面を、目地と明暗差のある石ブロックで塗る。
            /// kind は壁=0、床=1、天井=2。
            func stoneSurface(_ corners: [CGPoint], depth: Int, seed: Int, kind: Int) {
                let outline = polygon(corners)
                let mortar = Color(red: 0.055, green: 0.052, blue: 0.047)
                ctx.fill(outline, with: .color(mortar))

                let averageHeight = (distance(corners[0], corners[3]) + distance(corners[1], corners[2])) / 2
                let averageWidth = (distance(corners[0], corners[1]) + distance(corners[3], corners[2])) / 2
                let rowCount = max(1, min(9, Int(averageHeight / 25)))
                let rowHeight = max(1, averageHeight / Double(rowCount))
                let brickRatio = kind == 0 ? 1.8 : 2.25
                let columnCount = max(1, min(14, Int(averageWidth / max(18, rowHeight * brickRatio))))
                let step = 1.0 / Double(columnCount)
                let depthShade = max(0.48, 1.0 - Double(depth) * 0.082)
                let strokeWidth = max(0.7, min(1.5, rowHeight * 0.055))

                let base: (red: Double, green: Double, blue: Double)
                switch kind {
                case 1:
                    base = (0.17, 0.16, 0.13)
                case 2:
                    base = (0.105, 0.10, 0.085)
                default:
                    base = (0.30, 0.275, 0.235)
                }

                for row in 0..<rowCount {
                    let v0 = Double(row) / Double(rowCount)
                    let v1 = Double(row + 1) / Double(rowCount)
                    let stagger = row.isMultiple(of: 2) ? 0 : step * 0.5
                    var boundaries = [0.0]
                    var next = step + stagger
                    while next < 1 {
                        boundaries.append(next)
                        next += step
                    }
                    boundaries.append(1)

                    for column in 0..<(boundaries.count - 1) {
                        let u0 = boundaries[column]
                        let u1 = boundaries[column + 1]
                        let points = [
                            surfacePoint(u0, v0, corners: corners),
                            surfacePoint(u1, v0, corners: corners),
                            surfacePoint(u1, v1, corners: corners),
                            surfacePoint(u0, v1, corners: corners)
                        ]
                        let brick = polygon(points)
                        let tone = (row * 7 + column * 11 + seed * 13 + depth * 5) % 7
                        let variation = Double(tone - 3) * 0.014
                        let planeShade = kind == 0 ? 1.0 : (kind == 1 ? 0.76 : 0.58)
                        let shade = depthShade * planeShade
                        let color = Color(
                            red: max(0, min(1, (base.red + variation) * shade)),
                            green: max(0, min(1, (base.green + variation) * shade)),
                            blue: max(0, min(1, (base.blue + variation) * shade))
                        )
                        ctx.fill(brick, with: .color(color))
                        ctx.stroke(brick, with: .color(mortar), lineWidth: strokeWidth)

                        var highlight = Path()
                        highlight.move(to: points[0])
                        highlight.addLine(to: points[1])
                        let highlightOpacity = max(0.025, 0.09 - Double(depth) * 0.009)
                        ctx.stroke(
                            highlight,
                            with: .color(Color.white.opacity(highlightOpacity)),
                            lineWidth: 0.7
                        )
                    }
                }
            }

            // 正面が壁に当たる深さまでを描画対象にする
            var depth = 0
            while depth < maxDepth && !isWallRelative(depth + 1, 0) {
                depth += 1
            }

            // 奥から手前へ描く。各マスの床・天井を敷いてから壁を重ね、奥の面を隠す。
            for d in stride(from: depth, through: 0, by: -1) {
                for i in lateralOrder(depth: d) {
                    if isWallRelative(d, i) { continue }

                    let z0 = Double(d) + 0.5    // このマスの手前側の奥行き
                    let z1 = Double(d) + 1.5    // このマスの奥側の奥行き
                    let xl = Double(i) - 0.5    // このマスの左端の横位置
                    let xr = Double(i) + 0.5    // このマスの右端の横位置
                    let showsGoalDoor = i == 0
                        && (1...2).contains(d)
                        && map.cell(at: positionRelative(d, i)) == .goal

                    stoneSurface([
                        project(xl, 0.5, z0), project(xr, 0.5, z0),
                        project(xr, 0.5, z1), project(xl, 0.5, z1)
                    ], depth: d, seed: i + d * 3, kind: 2)
                    stoneSurface([
                        project(xl, -0.5, z1), project(xr, -0.5, z1),
                        project(xr, -0.5, z0), project(xl, -0.5, z0)
                    ], depth: d, seed: i + d * 5, kind: 1)

                    // ドア画像の透過部分から奥が見えないよう、ゴール面に石壁を敷く。
                    if showsGoalDoor {
                        stoneSurface([
                            project(xl, 0.5, z0), project(xr, 0.5, z0),
                            project(xr, -0.5, z0), project(xl, -0.5, z0)
                        ], depth: d, seed: i + d * 17, kind: 0)
                    }

                    // 正面の壁
                    if isWallRelative(d + 1, i) {
                        stoneSurface([
                            project(xl, 0.5, z1), project(xr, 0.5, z1),
                            project(xr, -0.5, z1), project(xl, -0.5, z1)
                        ], depth: d, seed: i + d * 7, kind: 0)
                    }

                    // 左の壁
                    if isWallRelative(d, i - 1) {
                        stoneSurface([
                            project(xl, 0.5, z0), project(xl, 0.5, z1),
                            project(xl, -0.5, z1), project(xl, -0.5, z0)
                        ], depth: d, seed: i + d * 11 + 1, kind: 0)
                    }

                    // 右の壁
                    if isWallRelative(d, i + 1) {
                        stoneSurface([
                            project(xr, 0.5, z0), project(xr, 0.5, z1),
                            project(xr, -0.5, z1), project(xr, -0.5, z0)
                        ], depth: d, seed: i + d * 13 + 2, kind: 0)
                    }

                    // 周囲の石壁を描いた後にドアを置き、レンガ面との重なりを防ぐ。
                    if showsGoalDoor {
                        let topLeft = project(xl, 0.5, z0)
                        let bottomRight = project(xr, -0.5, z0)
                        ctx.draw(
                            doorImage,
                            in: CGRect(
                                x: topLeft.x,
                                y: topLeft.y,
                                width: bottomRight.x - topLeft.x,
                                height: bottomRight.y - topLeft.y
                            )
                        )
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)          // 3D表示領域は正方形(仕様書§12.6)
        .background(Color(red: 0.025, green: 0.024, blue: 0.022))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 0.48, green: 0.44, blue: 0.36).opacity(0.8), lineWidth: 1.5)
        }
    }
}
