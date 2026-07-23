# PeriodicDelaunay2D

周期境界を持つ２Ｄドロネー図（`LUX.Delaunay.D2.Periodic`）のデモアプリケーション。

A demo application of the 2D **periodic** Delaunay triangulation library `LUX.Delaunay.D2.Periodic` (a Delaunay triangulation of the flat torus).

![](--------/_SCREENSHOT/PeriodicDelaunay2D.png)

- 基本領域 `[0,L)²` を中央に、周囲へ周期タイルを敷き詰めて描画する（中央の実体を濃色、周囲8コピーを50%）。空円は基本領域の実体のぶんだけを描く。
- 空白をクリックで点の追加、既存点の近くをクリックで削除。ボタンは以下の4つ：
  - `Clear` … 全消去
  - `Add x10 ( Random )` … 一様乱数で点をまとめて追加
  - `Add x10 ( Poisson-disk )` … `FindMaxCircle`（最大半径の空円）の中心へ追加を繰り返し、空いた所から順に埋める（ブルーノイズ的な点配置）
  - `Del x10` … ランダムに削除
- ライブラリは被覆空間もゴースト点も使わない**常時最小表現**（頂点 n・面 2n。n=1 でも面2枚のΔ複体）。`Poins` はサイト数、`Faces` は面数（常に 2n）を示す。追加・削除とも局所処理で、削除も通常は再構築しない。

ライブラリ本体とアルゴリズムの解説は
[`_LIBRARY/LUXOPHIA/LUX.Delaunay/D2/Periodic`](_LIBRARY/LUXOPHIA/LUX.Delaunay/D2/Periodic/ja/README.md)
を参照。

## Build

- Delphi (RAD Studio) / FireMonkey + Skia（`GlobalUseSkia = True`）
- `PeriodicDelaunay2D.dproj` を開いて Win32/Win64 をビルドする。

## Libraries (git subtree)

- `_LIBRARY/LUXOPHIA/LUX`
- `_LIBRARY/LUXOPHIA/LUX.CG2D`
- `_LIBRARY/LUXOPHIA/LUX.Delaunay`
