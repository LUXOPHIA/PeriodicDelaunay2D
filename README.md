# PeriodicDelaunay2D

[English](README.md) | [日本語](ja/README.md)

An interactive demo application for `LUX.Delaunay.D2.Periodic` — a 2D Delaunay triangulation with **periodic boundary conditions**, i.e. a Delaunay triangulation of the flat torus $\mathbb{T}^2_L = \mathbb{R}^2/L\mathbb{Z}^2$. Sites can be inserted and deleted incrementally with the mouse; the triangulation, its circumcircles, and the dual Voronoi diagram are rendered live with Skia on FireMonkey.

![Screenshot](--------/_SCREENSHOT/PeriodicDelaunay2D.png)

## 利用ライブラリ

* [**LUX**](https://github.com/LUXOPHIA/LUX) ：Base mathematical utility library for Delphi.
* [**LUX.CG2D**](https://github.com/LUXOPHIA/LUX.CG2D) ：2D scene-graph rendering library based on Skia4Delphi.
* [**LUX.Delaunay**](https://github.com/LUXOPHIA/LUX.Delaunay) ：Delaunay complex library supporting dynamic insertion and deletion.

## 1. Overview

- The fundamental domain $[0,L)^2$ sits at the center of the view, tiled periodically around it: the central **real** triangulation is drawn in solid color and the 8 surrounding copies at 50 % alpha. Empty circumcircles (green) are drawn only for the fundamental-domain faces, Voronoi edges are black, sites are red, and the pink lines are the $3 \times 3$ tile boundaries.
- The underlying model `TPeriDelaunay2D` keeps the triangulation of the torus in the **minimal representation at all times** — $n$ vertices and $2n$ faces, valid even for $n = 1$ — with **no ghost-point replication and no covering-space data structure** (the $3 \times 3$ copies exist only in the rendering). Each face instead carries per-corner lattice offsets that define its own local lift into the universal cover $\mathbb{R}^2$.
- All geometric decisions use **exact integer predicates** on a quantized grid, combined with a lattice-equivariant symbolic perturbation, so floating-point misclassification — the usual source of structural corruption in Delaunay codes — cannot occur.
- Both insertion and deletion are **local operations**; deletion falls back to a rebuild only for degenerate configurations or trivially small site counts ($n \le 3$).

## 2. Mathematical Background

### 2.1 The flat torus and periodic point sets

The domain is the square flat torus of edge length $L$,

```math
\mathbb{T}^2_L \;=\; \mathbb{R}^2 / L\mathbb{Z}^2 ,
\qquad
\pi : \mathbb{R}^2 \to \mathbb{T}^2_L
\tag{1}
```

with quotient map $\pi$ (setting $L = 1$ gives the standard torus $\mathbb{T}^2 = \mathbb{R}^2/\mathbb{Z}^2$; the code exposes $L$ as `TPeriDelaunay2D.Size`). A finite site set $P = \{p_1,\dots,p_n\} \subset [0,L)^2$ determines the periodic point set

```math
\widetilde{P} \;=\; P + L\mathbb{Z}^2
\;=\; \{\, p + L z \mid p \in P,\; z \in \mathbb{Z}^2 \,\}.
\tag{2}
```

### 2.2 Delaunay triangulation on the torus

A triangle with lifted vertices $\hat{c}_1,\hat{c}_2,\hat{c}_3 \in \mathbb{R}^2$ is *Delaunay* iff its open circumdisk $D$ is empty of all periodic copies [7]:

```math
D(\hat{c}_1,\hat{c}_2,\hat{c}_3) \,\cap\, \widetilde{P} \;=\; \varnothing .
\tag{3}
```

The projection under $\pi$ of all such triangles is the Delaunay triangulation of $\mathbb{T}^2_L$. Since $\chi(\mathbb{T}^2) = 0$, Euler's formula fixes the complex size:

```math
V = n, \qquad E = 3n, \qquad F = 2n .
\tag{4}
```

Even $n = 1$ is a valid Δ-complex: one vertex and two faces whose corners reference the *same* vertex instance under different lattice offsets (the code seeds exactly this in `SeedTwo`).

The standard implementation technique works in a $3 \times 3$ (in 3D, $3^3$) sheeted covering space with ghost copies of every site [1][3], or restricts direct quotient-space insertion to point sets dense enough to guarantee simpliciality [2]. This library instead represents the quotient directly for *every* $n$, including the sparse regime where a vertex is Delaunay-adjacent to its own periodic images and faces have self-edges.

### 2.3 Circumradius bound, lattice offsets, and canonical representatives

Any empty disk must avoid the four axis/diagonal lattice copies of any single site, which bounds every circumdiameter:

```math
2R(\sigma) \;\le\; \sqrt{2}\,L
\qquad \text{for every Delaunay face } \sigma .
\tag{5}
```

Vertex coordinates are always stored canonically in $[0,L)^2$. Each face stores a lattice offset $o_K$ per corner $K \in \{1,2,3\}$ (`TPeriFace2D.Off`, 2 bits per axis), defining the corner's lift

```math
\hat{c}_K \;=\; p_K + L\,o_K ,
\qquad
o_K \in \{0,1,2\}^2 ,
\tag{6}
```

so each face carries its own lift into the universal cover; the lifts of adjacent faces differ by a lattice translation (`NeigShift`). Offsets are normalized at face creation — the per-axis minimum is forced to $0$ (`NewFaceG`) — which selects a canonical representative and, by bound (5), keeps every offset within $\{0,1,2\}$. Entities therefore never drift away from the fundamental domain and no periodic "re-wrapping pass" is ever needed.

### 2.4 Quantization and exact integer predicates

The edge length is snapped to a power-of-two grid: with $L = M\cdot2^{E}$, $M \in [0.5,1)$,

```math
q \;=\; 2^{\,E-17},
\qquad
L \;=\; K q,
\qquad
K \in [\,2^{16}, 2^{17}\,],
\tag{7}
```

and all site coordinates are snapped to multiples of $q$ (relative error $\sim L\cdot2^{-16}$, invisible in practice). All geometry then lives on an integer grid, so the orientation predicate

```math
\operatorname{orient}(Q,L,R) \;=\; (L-Q) \times (R-Q)
\tag{8}
```

is evaluated exactly in 64-bit integers (`OrientG`), and the in-circle predicate — the sign of the $4 \times 4$ lifted determinant

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

— is evaluated exactly via 128-bit integer accumulation (`InCircleSign` / `Acc128`).

### 2.5 Lattice-equivariant symbolic perturbation

Cocircular ties ($\operatorname{incircle} = 0$) are broken deterministically by Simulation of Simplicity [6]: site $i$ of rank $r_i$ is treated as lifted by an infinitesimal $\varepsilon^{r_i}$ on the paraboloid, and the tie is resolved by scanning cofactors in rank order (`InCirclePert`). Crucially, the perturbation is assigned *per site*, so all periodic images of one site share the same rank and their cofactors are summed together — the perturbation is **lattice-equivariant**, which also resolves the *structural* cocircularities caused by translate pairs $(w,\, w + L e)$ of a single vertex. Only unresolvable super-degeneracies are rejected without modifying anything (`AddPoin` returns `nil`; deletion returns `False`).

### 2.6 Insertion: Bowyer–Watson in the universal cover

Insertion follows Bowyer–Watson [4][5], run on face lifts. One lift $\hat{p}$ of the new site $p$ is fixed, and the cavity is collected by breadth-first search as a set of pairs

```math
C(\hat{p}) \;=\; \{\, (\sigma, t) \in F \times \mathbb{Z}^2
\;\mid\; \hat{p} \in D(\sigma + L t) \,\},
\tag{10}
```

where the same face entity $\sigma$ may legitimately appear under *two different* translations $t$ when its circumdisk contains several periodic images of $p$ (`InsertPoin`; visited lifts are deduplicated by a (face, translation) dictionary).

- **Normal case** — $p$ is not Delaunay-adjacent to its own periodic images: the cavity is retriangulated by the usual cone over the boundary edges. Validity is verified exactly first: no cone-face circumdisk may contain any of the 8 neighboring images of $p$ (by (5) only those can qualify), and no boundary edge may have its outer side inside the cavity. New faces are sewn by scanning `CanWeld`, which in the universal cover must require not only vertex identity but that the **lattice displacement of the shared edge matches in mirror** — two lifts of the same vertex are distinct points.
- **Sparse case** — $p$ is adjacent to its own images, so faces with a self-edge $p$–$p$ are required and a cone would be wrong: the star (fan) of $\hat{p}$ is built directly by **gift-wrapping** over a candidate set consisting of the hole-boundary vertices with their translates plus the lattice images of $p$. Fan faces projected to the torus may coincide, so instances are identified by a rotation/translation-normalized key, and every adjacency is resolved geometrically (the Delaunay third vertex across each edge). The complete sewing plan is validated — including the Euler count $F_{\text{new}} = F_{\text{killed}} + 2$ from (4) — *before* the mesh is touched; any tie or inconsistency aborts with the triangulation unchanged.

Point location is jump-and-walk — $\lceil n^{1/3} \rceil$ random samples, then a stochastic walk crossing edges with a cumulative lattice translation, all with exact predicates — with a full-scan fallback for degenerate walks (`FindHitLift`).

### 2.7 Deletion: star removal and Delaunay-ear refill

To delete vertex $v$, the star around one lift $\hat{v}$ is traversed by corner cycling (the same face entity may be visited twice if it references $v$ at two corners), and the hole's boundary polygon is extracted in lift coordinates. The hole is filled by **Delaunay ears**: an ear is accepted only if its circumdisk contains no link vertex *nor any of their lattice translates* (`TryLocalDelete` / `CutEars`). Sewing is planned in two stages — internal fill-to-fill edges matched by exact lift coordinates; and, when the hole **wraps around the torus** and borders a translated copy of itself, the neighboring hole's translation $\mu$ is determined geometrically from the star lifts and the two fills are sewn across the wrap. The full plan is validated before the mesh is modified; on any degeneracy nothing is touched and the caller falls back to an $O(1)$ rebuild from the site list, which is also used for $n \le 3$. The counters `LocalDelN` / `RebuildDelN` / `StarInsN` report how often each path runs.

## 3. Architecture

```
[1] Ownership — Main.pas (Clear / Add x10 / Del x10, click-to-add/delete)

・TForm1
  ┣・_Delaunay :TPeriDelaunay2D   ･･･ the model
  ┗・Viewer1 :TPeriDelaunayViewer ･･･ reads the model, never writes to it

[2] Model — LUX.Delaunay.D2.Periodic

・TPeriDelaunay2D                  ･･･ AddPoin / DeletePoin / FindMaxCircle …
  ┣・Poins :TPeriPoinSet2D
  ┃  ┗・TPeriPoin2D              ･･･ Site
  ┗・Faces :TPeriFaceSet2D
     ┗・TPeriFace2D               ･･･ Off, CanWeld, NeigShift

[3] Viewer — LUX.Delaunay.D2.Periodic.Viewer   (x2 = solid layer + 50 % copies)

・TPeriDelaunayViewer (TFrame)
  ┣・TPeriDelaunayTrias (x2)
  ┣・TPeriDelaunayCircs
  ┣・TPeriDelaunayVolos
  ┣・TPeriDelaunayGrids
  ┣・TPeriDelaunayPoins (x2)
  ┗・TCGCamera on TCGLayers

[4] Unit dependencies

・Main.pas
  ┣・LUX.Delaunay.D2.Periodic
  ┃  ┗・LUX.Data.Model.TriFlip   ･･･ corner-cycling triangle-mesh container
  ┃     ┣・TTriPoin2D<F>
  ┃     ┣・TTriPoinSet2D<P>
  ┃     ┣・TTriFace2D<P,F>
  ┃     ┗・TTriFaceSet2D
  ┗・LUX.Delaunay.D2.Periodic.Viewer
     ┗・LUX.CG2D                  ･･･ 2D scene graph on an ISkCanvas (Skia)
        ┣・TCGLayer
        ┣・TCGCirc
        ┣・TCGTria
        ┣・TCGLine
        ┗・TCGCamera
```

The TriFlip container navigates by corner indices, not vertex identity, so it hosts Δ-complexes unmodified; the periodic layer only adds lattice offsets and lifted geometry. The viewer is pure visualization: it tiles the torus faces over a fixed $3 \times 3$ grid (camera field $2L \times 2L$) and never influences the model.

```
・PeriodicDelaunay2D/
  ┣・PeriodicDelaunay2D.dpr / .dproj ･･･ FMX application project (Win32/Win64)
  ┣・Main.pas / Main.fmx             ･･･ main form: model + viewer
  ┣・PeriodicDelaunay_NoCover_JA.tex ･･･ technical note (Japanese, with PDF)
  ┣・--------/_SCREENSHOT/           ･･･ screenshot
  ┣・ja/README.md                    ･･･ this document in Japanese
  ┗・_LIBRARY/LUXOPHIA/              ･･･ vendored libs (git subtree, read-only)
     ┣・LUX/                         ･･･ base library: vectors, lists, ...
     ┃  ┗・Data/Model/TriFlip/      ･･･ corner-cycling triangle-mesh container
     ┣・LUX.CG2D/                    ･･･ 2D scene graph + Skia viewer
     ┗・LUX.Delaunay/
        ┗・D2/Periodic/              ･･･ LUX.Delaunay.D2.Periodic (+ .Viewer)
```

Vendored subtrees: [LUX](https://github.com/LUXOPHIA/LUX) · [LUX.CG2D](https://github.com/LUXOPHIA/LUX.CG2D) · [LUX.Delaunay](https://github.com/LUXOPHIA/LUX.Delaunay) — the periodic algorithm is documented in detail in [`_LIBRARY/LUXOPHIA/LUX.Delaunay/D2/Periodic`](_LIBRARY/LUXOPHIA/LUX.Delaunay/D2/Periodic/README.md).

## 4. Usage / Controls

| Control | Action |
|---|---|
| Click on empty space | Add a site at the clicked position (wrapped into $[0,L)^2$) |
| Click near an existing site (within 6 units) | Delete that site |
| `Clear` | Remove all sites |
| `Add x10 ( Random )` | Add 10 uniform-random sites |
| `Add x10 ( Poisson-disk )` | Insert 10 times at the center of the current largest empty circumcircle (`FindMaxCircle`), yielding a blue-noise / Poisson-disk-like distribution |
| `Del x10` | Delete 10 randomly chosen sites |

The label shows `Poins` (number of sites $n$) and `Faces` (number of faces, always $2n$ by (4)). The fundamental domain is set to $[0,300)^2$ at startup.

## 5. Building

- **IDE**: RAD Studio (Delphi), FireMonkey (FMX) application.
- **Platforms** (from `PeriodicDelaunay2D.dproj`): Win32 and Win64 (default: Win64).
- **Skia**: the project sets `GlobalUseSkia := True` and the viewer renders on `ISkCanvas`, so a Skia-enabled RAD Studio (12 or later, Skia is bundled) is required; on a non-Skia canvas the viewer draws nothing.
- All dependencies are vendored under `_LIBRARY/` as git subtrees — open `PeriodicDelaunay2D.dproj`, select the platform, and run. No package installation is needed.

## 6. References

1. M. Caroli, M. Teillaud, [*Computing 3D Periodic Triangulations*](https://doi.org/10.1007/978-3-642-04128-0_6), ESA 2009.
2. G. Osang, M. Rouxel-Labbé, M. Teillaud, [*Generalizing CGAL Periodic Delaunay Triangulations*](https://doi.org/10.4230/LIPIcs.ESA.2020.75), ESA 2020.
3. CGAL Manual, [*2D Periodic Triangulations*](https://doc.cgal.org/latest/Periodic_2_triangulation_2/index.html).
4. A. Bowyer, [*Computing Dirichlet tessellations*](https://doi.org/10.1093/comjnl/24.2.162), The Computer Journal 24(2), 1981.
5. D. F. Watson, [*Computing the n-dimensional Delaunay tessellation with application to Voronoi polytopes*](https://doi.org/10.1093/comjnl/24.2.167), The Computer Journal 24(2), 1981.
6. H. Edelsbrunner, E. P. Mücke, [*Simulation of Simplicity: A Technique to Cope with Degenerate Cases in Geometric Algorithms*](https://doi.org/10.1145/77635.77639), ACM TOG 9(1), 1990.
7. Wikipedia, [*Delaunay triangulation*](https://en.wikipedia.org/wiki/Delaunay_triangulation).

## 💖 [Embarcadero](https://www.embarcadero.com/) [**Delphi**](https://www.embarcadero.com/products/delphi)
Integrated Development Environment (IDE) for Creating Native Cross-Platform Apps.
### Free Download: [**Delphi** Community Edition](https://www.embarcadero.com/products/delphi/starter)
