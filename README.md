# PeriodicDelaunay2D

[日本語](ja/README.md)

A demo application of `LUX.Delaunay.D2.Periodic` — a 2D **periodic** Delaunay triangulation, i.e. a Delaunay triangulation of the flat torus `T = [0,L)²`.

![](https://github.com/LUXOPHIA/PeriodicDelaunay2D/raw/main/--------/_SCREENSHOT/PeriodicDelaunay2D.png)

## What it shows

- The fundamental domain `[0,L)²` sits at the center, tiled periodically around it — the central **real** triangulation is drawn in solid colour and the 8 surrounding copies at 50 %. Empty circles are drawn only for the fundamental-domain faces. The pink lines are the `3 × 3` tile boundaries.
- Click empty space to **add** a site; click near an existing site to **delete** it.
- Buttons:
  - `Clear` — remove everything.
  - `Add x10 ( Random )` — add 10 uniform-random sites.
  - `Add x10 ( Poisson-disk )` — repeatedly insert at the centre of the current largest empty circle (`FindMaxCircle`), which drives a blue-noise / Poisson-disk-like distribution.
  - `Del x10` — delete 10 random sites.
- `Poins` = number of sites, `Faces` = number of faces (always `2n`).

## The library

`LUX.Delaunay.D2.Periodic` keeps the Delaunay triangulation of the flat torus in the **minimal representation at all times** — `n` vertices and `2n` faces, even for `n = 1` (a 2-face Δ-complex) — with **no covering space and no ghost points**. Insertion and deletion are both local; exact integer predicates and a lattice-equivariant symbolic perturbation make it robust.

Full description and algorithm:
[`_LIBRARY/LUXOPHIA/LUX.Delaunay/D2/Periodic`](_LIBRARY/LUXOPHIA/LUX.Delaunay/D2/Periodic/README.md).

## Build

- Delphi (RAD Studio) / FireMonkey + Skia (`GlobalUseSkia = True`).
- Open `PeriodicDelaunay2D.dproj` and build for Win32 / Win64.

## Libraries (git subtree)

- `_LIBRARY/LUXOPHIA/LUX`
- `_LIBRARY/LUXOPHIA/LUX.CG2D`
- `_LIBRARY/LUXOPHIA/LUX.Delaunay`
