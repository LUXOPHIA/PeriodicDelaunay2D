# PeriodicDelaunay2D

[English](../README.md)

`LUX.Delaunay.D2.Periodic` ―― 周期境界を持つ２Ｄドロネー図（平坦トーラス `T = [0,L)²` 上のドロネー三角形分割）のデモアプリケーション。

![](https://github.com/LUXOPHIA/PeriodicDelaunay2D/raw/main/--------/_SCREENSHOT/PeriodicDelaunay2D.png)

## 画面

- 基本領域 `[0,L)²` を中央に、周囲へ周期タイルを敷き詰めて描画する。中央の**実体**の分割を濃色で、周囲8コピーを50%で描く。空円は基本領域の実体のぶんだけを描く。ピンクの線は `3 × 3` タイルの境界。
- 空白をクリックで点の**追加**、既存点の近くをクリックで**削除**。
- ボタン：
  - `Clear` … 全消去。
  - `Add x10 ( Random )` … 一様乱数で点を10個追加。
  - `Add x10 ( Poisson-disk )` … `FindMaxCircle`（最大半径の空円）の中心へ追加を繰り返し、空いた所から順に埋める（ブルーノイズ的な点配置）。
  - `Del x10` … ランダムに10個削除。
- `Poins` はサイト数、`Faces` は面数（常に `2n`）。

## ライブラリ

`LUX.Delaunay.D2.Periodic` は、平坦トーラスのドロネー図を**常時最小表現**（頂点 `n` 個・面 `2n` 枚。`n = 1` でも面2枚のΔ複体）で保つ。**被覆空間もゴースト点も使わない**。追加・削除とも局所処理で、厳密整数述語と格子同変な記号摂動によって頑健である。

アルゴリズムの詳細：
[`_LIBRARY/LUXOPHIA/LUX.Delaunay/D2/Periodic`](../_LIBRARY/LUXOPHIA/LUX.Delaunay/D2/Periodic/ja/README.md)。

## ビルド

- Delphi (RAD Studio) / FireMonkey + Skia（`GlobalUseSkia = True`）。
- `PeriodicDelaunay2D.dproj` を開いて Win32 / Win64 をビルドする。

## ライブラリ（git subtree）

- `_LIBRARY/LUXOPHIA/LUX`
- `_LIBRARY/LUXOPHIA/LUX.CG2D`
- `_LIBRARY/LUXOPHIA/LUX.Delaunay`
