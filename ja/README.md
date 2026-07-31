# PeriodicDelaunay2D

[English](../README.md) | [日本語](README.md)

`LUX.Delaunay.D2.Periodic` の対話的デモアプリケーション ―― **周期境界条件**を持つ２Ｄドロネー三角形分割、すなわち平坦トーラス $\mathbb{T}^2_L = \mathbb{R}^2/L\mathbb{Z}^2$ 上のドロネー三角形分割である。サイトはマウスで逐次的に追加・削除でき、三角形分割・外接円・双対のボロノイ図が FireMonkey 上の Skia でリアルタイムに描画される。

![Screenshot](../--------/_SCREENSHOT/PeriodicDelaunay2D.png)

## 利用ライブラリ

* [**LUX**](https://github.com/LUXOPHIA/LUX) ：Delphi のための基盤数学ライブラリ。
* [**LUX.CG2D**](https://github.com/LUXOPHIA/LUX.CG2D) ：Skia4Delphi による２Ｄシーングラフ描画ライブラリ。
* [**LUX.Delaunay**](https://github.com/LUXOPHIA/LUX.Delaunay) ：動的な追加・削除に対応するドロネー複体ライブラリ。

## 1. 概要

- 基本領域 $[0,L)^2$ を画面中央に置き、その周囲へ周期タイルを敷き詰めて描画する。中央の**実体**の分割は濃色で、周囲8コピーはアルファ 50 % で描く。空円（緑）は基本領域の面のぶんだけ描き、ボロノイ辺は黒、サイトは赤、ピンクの線は $3 \times 3$ タイルの境界である。
- 基盤のモデル `TPeriDelaunay2D` は、トーラスの三角形分割を**常時最小表現** ―― 頂点 $n$ 個・面 $2n$ 枚、$n = 1$ でも成立 ―― で保ち、**ゴースト点の複製も被覆空間のデータ構造も使わない**（$3 \times 3$ のコピーは描画にのみ存在する）。その代わり各面が角ごとの格子オフセットを持ち、普遍被覆 $\mathbb{R}^2$ への面固有のリフトを定める。
- 幾何判定はすべて量子化グリッド上の**厳密整数述語**で行い、格子同変な記号摂動と組み合わせることで、ドロネー実装の構造破壊の常因である浮動小数の誤判定が原理的に存在しない。
- 追加・削除はともに**局所処理**である。削除が再構築へ退避するのは、退化配置と極小サイト数（$n \le 3$）のときだけである。

## 2. 数学的背景

### 2.1 平坦トーラスと周期点集合

領域は一辺 $L$ の正方形平坦トーラス

```math
\mathbb{T}^2_L \;=\; \mathbb{R}^2 / L\mathbb{Z}^2 ,
\qquad
\pi : \mathbb{R}^2 \to \mathbb{T}^2_L
\tag{1}
```

であり、$\pi$ は商写像である（$L = 1$ とすれば標準トーラス $\mathbb{T}^2 = \mathbb{R}^2/\mathbb{Z}^2$。コードでは $L$ を `TPeriDelaunay2D.Size` として公開する）。有限のサイト集合 $P = \{p_1,\dots,p_n\} \subset [0,L)^2$ は周期点集合

```math
\widetilde{P} \;=\; P + L\mathbb{Z}^2
\;=\; \{\, p + L z \mid p \in P,\; z \in \mathbb{Z}^2 \,\}
\tag{2}
```

を定める。

### 2.2 トーラス上のドロネー三角形分割

リフトされた頂点 $\hat{c}_1,\hat{c}_2,\hat{c}_3 \in \mathbb{R}^2$ を持つ三角形が*ドロネー*であるとは、その開外接円板 $D$ がすべての周期コピーを含まないことをいう [7]：

```math
D(\hat{c}_1,\hat{c}_2,\hat{c}_3) \,\cap\, \widetilde{P} \;=\; \varnothing .
\tag{3}
```

このような三角形すべてを $\pi$ で射影したものが $\mathbb{T}^2_L$ のドロネー三角形分割である。$\chi(\mathbb{T}^2) = 0$ なので、オイラーの公式により複体の大きさは

```math
V = n, \qquad E = 3n, \qquad F = 2n
\tag{4}
```

に確定する。$n = 1$ でも有効なΔ複体である：1頂点・2面で、面の角が*同じ*頂点の実体を異なる格子オフセットで参照する（コードは `SeedTwo` でまさにこれを種として作る）。

標準的な実装技法は、全サイトのゴーストコピーを持つ $3 \times 3$（３次元では $3^3$）枚の被覆空間で作業するか [1][3]、単体性が保証されるほど点集合が密な場合に限って商空間へ直接挿入する [2]。本ライブラリはそれらと異なり、*あらゆる* $n$ ―― 頂点が自分自身の周期像とドロネー隣接し面が自己辺を持つ疎な領域を含めて ―― で商空間を直接表現する。

### 2.3 外接円半径の上界・格子オフセット・正準代表元

いかなる空円板も任意の1サイトの軸・対角方向の格子コピー4点を避けねばならないので、すべての外接円直径が抑えられる：

```math
2R(\sigma) \;\le\; \sqrt{2}\,L
\qquad \text{（すべてのドロネー面 } \sigma \text{ について）} .
\tag{5}
```

頂点座標は常に正準座標 $[0,L)^2$ で格納する。各面は角 $K \in \{1,2,3\}$ ごとに格子オフセット $o_K$（`TPeriFace2D.Off`・軸ごと2ビット）を持ち、角のリフト

```math
\hat{c}_K \;=\; p_K + L\,o_K ,
\qquad
o_K \in \{0,1,2\}^2
\tag{6}
```

を定める。すなわち各面は普遍被覆への面固有のリフトを持ち、隣接面のリフトとは格子平行移動だけずれる（`NeigShift`）。オフセットは面の生成時に必ず正規化され ―― 軸ごとの最小値を $0$ に揃える（`NewFaceG`）――、これが正準代表元を選ぶとともに、上界 (5) によりオフセットは $\{0,1,2\}$ に収まる。したがって実体が基本領域から乖離していくことはなく、「散らばった実体を後から巻き戻す」処理は原理的に不要である。

### 2.4 座標の量子化と厳密整数述語

一辺は 2 の冪グリッドへスナップされる：$L = M\cdot2^{E}$、$M \in [0.5,1)$ として

```math
q \;=\; 2^{\,E-17},
\qquad
L \;=\; K q,
\qquad
K \in [\,2^{16}, 2^{17}\,]
\tag{7}
```

とし、サイト座標も $q$ の整数倍へスナップする（相対誤差 $\sim L\cdot2^{-16}$、実用上見えない）。これにより全ての幾何は整数格子上にあり、向き述語

```math
\operatorname{orient}(Q,L,R) \;=\; (L-Q) \times (R-Q)
\tag{8}
```

は 64 ビット整数で厳密に評価でき（`OrientG`）、空円述語 ―― リフトされた $4 \times 4$ 行列式の符号

```math
\operatorname{incircle}(A,B,C,Q) \;=\;
\det
\begin{pmatrix}
A_x - Q_x & A_y - Q_y & \lVert A-Q \rVert^2 \\
B_x - Q_x & B_y - Q_y & \lVert B-Q \rVert^2 \\
C_x - Q_x & C_y - Q_y & \lVert C-Q \rVert^2
\end{pmatrix}
\tag{9}
```

―― は 128 ビット整数の累算で厳密に評価できる（`InCircleSign` / `Acc128`）。

### 2.5 格子同変な記号摂動

共円のタイ（$\operatorname{incircle} = 0$）は Simulation of Simplicity [6] により決定的に解消する：順位 $r_i$ のサイト $i$ を放物面上で無限小 $\varepsilon^{r_i}$ だけ持ち上げたとみなし、余因子を順位の昇順に走査して符号を決める（`InCirclePert`）。要点は摂動を*サイト単位*で与えることである。同一サイトの全ての周期像が同じ順位を共有し余因子が束ねられるため、摂動は**格子同変**であり、1つの頂点の平行移動対 $(w,\, w + L e)$ が引き起こす*構造的な*共円も解消される。解消できない超退化だけが、何も変更せずに拒否される（`AddPoin` は `nil` を、削除は `False` を返す）。

### 2.6 追加：普遍被覆上の Bowyer–Watson

追加は Bowyer–Watson 法 [4][5] を面のリフト上で実行する。追加サイト $p$ のリフト $\hat{p}$ をひとつ固定し、キャビティを対の集合

```math
C(\hat{p}) \;=\; \{\, (\sigma, t) \in F \times \mathbb{Z}^2
\;\mid\; \hat{p} \in D(\sigma + L t) \,\}
\tag{10}
```

として幅優先探索で集める。外接円板が $p$ の複数の周期像を含む場合、同じ面の実体 $\sigma$ が*異なる2つの*平行移動 $t$ で正当に現れ得る（`InsertPoin`。訪問済みリフトは（面, 平行移動）の辞書で同一視する）。

- **通常の場合** ―― $p$ が自分の周期像とドロネー隣接しない場合：キャビティは境界辺への通常の錐張りで再分割する。妥当性は先に厳密に検証する：どの錐面の外接円板も $p$ の隣接する8つの周期像を含んではならず（(5) により候補はそれらに限る）、境界辺の外側がキャビティに含まれてもいけない。新しい面は `CanWeld` の走査で縫合するが、普遍被覆では頂点の同一性だけでは足りず、**共有辺の格子変位が鏡像で一致すること**まで要求する ―― 同じ頂点の2つのリフトは別の点だからである。
- **疎な場合** ―― $p$ が自分の周期像と隣接し、自己辺 $p$–$p$ を持つ面が必要で錐張りは正しくない場合：$\hat{p}$ のスター（扇）を、穴の境界頂点とその平行移動像に $p$ の格子像を加えた候補集合上の**ギフトラッピング**で直接構築する。扇の面はトーラスへ射影すると一致し得るので、回転・平行移動の正規化キーでインスタンスを同一視し、すべての隣接は幾何計算（各辺の反対側のドロネー第3頂点）で解決する。縫合計画の全体は ―― (4) から従うオイラー計数 $F_{\text{new}} = F_{\text{killed}} + 2$ を含めて ―― メッシュに触れる*前に*検証され、タイや矛盾があれば分割を無傷のまま中止する。

位置検索はジャンプ＆ウォーク ―― 無作為標本 $\lceil n^{1/3} \rceil$ 個から出発し、累積格子平行移動つきの確率的歩行で辺を渡る。全て厳密述語 ―― であり、退化した歩行には全面走査の保険がある（`FindHitLift`）。

### 2.7 削除：星の除去とドロネー耳埋め戻し

頂点 $v$ の削除では、ひとつのリフト $\hat{v}$ の周りの星を角の巡回で辿り（同じ面の実体が2つの角で $v$ を参照していれば2回訪れる）、穴の境界多角形をリフト座標で取り出す。穴は**ドロネー耳**で埋める：耳が採用されるのは、その外接円板がリンク頂点も*その格子平行移動像も*含まないときに限る（`TryLocalDelete` / `CutEars`）。縫合は二段で計画する ―― 埋め草どうしの内部の辺はリフト座標の厳密一致で対にし、穴が**トーラスを巻いて**自身の平行移動コピーと接する場合は、隣の穴の平行移動 $\mu$ を星のリフトから幾何的に特定して巻き付き越しに埋め草どうしを縫う。計画の全体はメッシュ変更前に検証され、退化時は何も触れずにサイト列からの $O(1)$ 再構築へ退避する（$n \le 3$ も同様）。カウンタ `LocalDelN` / `RebuildDelN` / `StarInsN` が各経路の実行回数を報告する。

## 3. アーキテクチャ

```
[1] 所有関係 ― Main.pas （Clear / Add x10 / Del x10、クリックで追加・削除）

・TForm1
  ┣・_Delaunay :TPeriDelaunay2D   ･･･ モデル
  ┗・Viewer1 :TPeriDelaunayViewer ･･･ モデルを読むだけで書き換えない

[2] モデル ― LUX.Delaunay.D2.Periodic

・TPeriDelaunay2D                  ･･･ AddPoin / DeletePoin / FindMaxCircle …
  ┣・Poins :TPeriPoinSet2D
  ┃  ┗・TPeriPoin2D              ･･･ Site
  ┗・Faces :TPeriFaceSet2D
     ┗・TPeriFace2D               ･･･ Off, CanWeld, NeigShift

[3] ビューア ― LUX.Delaunay.D2.Periodic.Viewer （x2 ＝ 実体＋50% コピー）

・TPeriDelaunayViewer (TFrame)
  ┣・TPeriDelaunayTrias (x2)
  ┣・TPeriDelaunayCircs
  ┣・TPeriDelaunayVolos
  ┣・TPeriDelaunayGrids
  ┣・TPeriDelaunayPoins (x2)
  ┗・TCGCamera on TCGLayers

[4] ユニットの依存関係

・Main.pas
  ┣・LUX.Delaunay.D2.Periodic
  ┃  ┗・LUX.Data.Model.TriFlip   ･･･ 角番号で巡回する三角形メッシュコンテナ
  ┃     ┣・TTriPoin2D<F>
  ┃     ┣・TTriPoinSet2D<P>
  ┃     ┣・TTriFace2D<P,F>
  ┃     ┗・TTriFaceSet2D
  ┗・LUX.Delaunay.D2.Periodic.Viewer
     ┗・LUX.CG2D                  ･･･ ISkCanvas (Skia) 上の２Ｄシーングラフ
        ┣・TCGLayer
        ┣・TCGCirc
        ┣・TCGTria
        ┣・TCGLine
        ┗・TCGCamera
```

TriFlip コンテナは頂点の同一性ではなく角番号で巡回するため、Δ複体を無変更のまま載せられる。周期レイヤは格子オフセットとリフト幾何だけを付け加える。ビューアは純粋な可視化であり、トーラスの面を固定の $3 \times 3$ グリッド（カメラ視野 $2L \times 2L$）で敷き詰めて描くだけで、モデルには一切影響しない。

```
・PeriodicDelaunay2D/
  ┣・PeriodicDelaunay2D.dpr / .dproj ･･･ FMX アプリケーション（Win32/Win64）
  ┣・Main.pas / Main.fmx             ･･･ メインフォーム：モデル＋ビューア
  ┣・PeriodicDelaunay_NoCover_JA.tex ･･･ 技術ノート（日本語・PDF 同梱）
  ┣・--------/_SCREENSHOT/           ･･･ スクリーンショット
  ┣・ja/README.md                    ･･･ 本文書（日本語）
  ┗・_LIBRARY/LUXOPHIA/              ･･･ 同梱ライブラリ（subtree・編集禁止）
     ┣・LUX/                         ･･･ 基盤ライブラリ：ベクトル・リストなど
     ┃  ┗・Data/Model/TriFlip/      ･･･ 角番号巡回の三角形メッシュコンテナ
     ┣・LUX.CG2D/                    ･･･ ２Ｄシーングラフ＋ Skia ビューア
     ┗・LUX.Delaunay/
        ┗・D2/Periodic/              ･･･ LUX.Delaunay.D2.Periodic（＋ .Viewer）
```

同梱 subtree：[LUX](https://github.com/LUXOPHIA/LUX) · [LUX.CG2D](https://github.com/LUXOPHIA/LUX.CG2D) · [LUX.Delaunay](https://github.com/LUXOPHIA/LUX.Delaunay) ―― 周期アルゴリズムの詳細は [`_LIBRARY/LUXOPHIA/LUX.Delaunay/D2/Periodic`](../_LIBRARY/LUXOPHIA/LUX.Delaunay/D2/Periodic/ja/README.md) に記載されている。

## 4. 使い方・操作

| 操作 | 動作 |
|---|---|
| 空白をクリック | クリック位置にサイトを追加（$[0,L)^2$ へ巻き込む） |
| 既存サイトの近く（6単位以内）をクリック | そのサイトを削除 |
| `Clear` | 全サイトを削除 |
| `Add x10 ( Random )` | 一様乱数でサイトを10個追加 |
| `Add x10 ( Poisson-disk )` | 現在最大の空円の中心（`FindMaxCircle`）への追加を10回繰り返し、ブルーノイズ／ポアソンディスク的な点配置を得る |
| `Del x10` | ランダムに選んだサイトを10個削除 |

ラベルは `Poins`（サイト数 $n$）と `Faces`（面数。(4) により常に $2n$）を表示する。起動時の基本領域は $[0,300)^2$ である。

## 5. ビルド

- **IDE**：RAD Studio（Delphi）、FireMonkey（FMX）アプリケーション。
- **プラットフォーム**（`PeriodicDelaunay2D.dproj` より）：Win32・Win64（既定：Win64）。
- **Skia**：プロジェクトは `GlobalUseSkia := True` を設定し、ビューアは `ISkCanvas` に描画するため、Skia が使える RAD Studio（12 以降。Skia は同梱）が必要である。Skia でないキャンバスではビューアは何も描かない。
- 依存ライブラリはすべて `_LIBRARY/` に git subtree として同梱されている ―― `PeriodicDelaunay2D.dproj` を開き、プラットフォームを選んで実行するだけでよい。パッケージのインストールは不要である。

## 6. 参考文献

1. M. Caroli, M. Teillaud, [*Computing 3D Periodic Triangulations*](https://doi.org/10.1007/978-3-642-04128-0_6), ESA 2009.
2. G. Osang, M. Rouxel-Labbé, M. Teillaud, [*Generalizing CGAL Periodic Delaunay Triangulations*](https://doi.org/10.4230/LIPIcs.ESA.2020.75), ESA 2020.
3. CGAL Manual, [*2D Periodic Triangulations*](https://doc.cgal.org/latest/Periodic_2_triangulation_2/index.html).
4. A. Bowyer, [*Computing Dirichlet tessellations*](https://doi.org/10.1093/comjnl/24.2.162), The Computer Journal 24(2), 1981.
5. D. F. Watson, [*Computing the n-dimensional Delaunay tessellation with application to Voronoi polytopes*](https://doi.org/10.1093/comjnl/24.2.167), The Computer Journal 24(2), 1981.
6. H. Edelsbrunner, E. P. Mücke, [*Simulation of Simplicity: A Technique to Cope with Degenerate Cases in Geometric Algorithms*](https://doi.org/10.1145/77635.77639), ACM TOG 9(1), 1990.
7. Wikipedia, [*Delaunay triangulation*](https://en.wikipedia.org/wiki/Delaunay_triangulation).

## 💖 [Embarcadero](https://www.embarcadero.com/jp/) [**Delphi**](https://www.embarcadero.com/jp/products/delphi)
ネイティブなクロスプラットフォームアプリを開発するための統合開発環境（ＩＤＥ）。
### Free Download: [**Delphi** Community Edition](https://www.embarcadero.com/jp/products/delphi/starter)
