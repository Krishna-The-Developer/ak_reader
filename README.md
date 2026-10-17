# 📖 AK Reader (v1.0.2)

A physics-accurate, skeuomorphic e-reader built with Flutter. Engineered with isometric developable surface curl physics, real-time contact-bound sound synthesis, and an authentic wooden desk reading environment.

---

## 📦 Direct Downloads (v1.0.2 Installable APKs)

Pre-built, release-signed APK binaries for Android:

*pwdb_flav
 | Target Architecture | Binary File | Direct Download |
#---|---|---|---|
| Universal Release * | All ABIs (`arm64-v8a`, `armeabi-v7a`, `x86_64`) | `ak_reader-v1.0.2-universal.apk` | [Download Universal APK](https://github.com/Krishna-The-Developer/ak_reader/releases/download/v1.0.2/ak_reader-v1.0.2-universal.apk)
| ARM64 Optimized * | Pure 64-bit (`arm64-v8a` - Nothing Phone 2a, etc.) | `ak_reader-v1.0.2-arm64.apk` | [Download ARM64 APK](https://github.com/Krishna-The-Developer/ak_reader/releases/download/v1.0.2/ak_reader-v1.0.2-arm64.apk)

---

## 🏗 System Architecture Diagram

```text
+-------------------------------------------------------------------------------------+
-|                             WoodenDeskFrame                                          |
-|  - Real Oak Surface Canvas (wood_table_texture.jpg)                                   |
|  - Boundary-Aware Pointer Dispatcher:                                               |
|      * Desk Hit -> Trigger Wood Impact Knock (Modal Synthesis)                       |
|      * Book Hit -> Forward to Gesture Surface                                      |
|  - Radial Stationery Petal System (1 Top, 3 Left, 3 Right)                            |
+---------------------------------------+-----------------------------------------------+
                                          |
                                          v
+---------------------------------------+----------------------------------------------+
|                             HardcoverView                                           |
|  - Skeuomorphic Leather Casing with Vintage Brass Corner Reinforcements               |
|  - Spine Hinge Rotation Matrix: R_y(phi_cover)                                       |
|  - Central Ribbon Root Anchor Point (Top Headband)                                    |
+---------------------------------------+-----------------------------------------------+
                                          |
                                          v
+---------------------------------------+----------------------------------------------+
|                            RealisticPageCurl                                        |
|  - Isometric Developable Surface Generator                                           |
|  - Variable Euler / Clothoid Curvature Profile: kappa(s, t)                           |
|  - Directional Inversion Matrix: M_x = diag(-1, 1, 1) for Left-to-Right flips          |
|  - Dynamic Landing Incline Offset: epsilon = arcsin(h_stack / W)                     |
+---------------------++---------------------------------+--+----------------------------+
                      |                                   |
                      v                                   v
+---------------------+--------------------+  +------------+--------------------------+
|          RibbonBookmarkWidget             |  |               SoundService                 |
|  - Surface Following: B(sigma, t)        |  |  - Strict Contact-Duration Audio Loop      |
|  - Catenary Hanging Tail:                 |  |  - Gain Modulated by Angular Velocity      |
|      y(x) = h * (1 - cos(2*pi*x / L))     |  |      A_rustle(t) proportional to |dTheta|  |
|  - Zero Text Occlusion Geometry            |  |  - Contact Release -> 0ms Silence Cut      |
|  - Slide-Out Parchment Note Card          |  |  - Impact Burst Events: Knock & Landing    |
+----------------------------------------------+-  +----------------------------------------------+
```

---

## 🔄 Interaction & Physics Workflow

```text
[User Pointer Down on Page Margin]
       |
       +---> Start Low-Latency Rustle Audio Loop (Gain = 0.0)
       |
[Pointer Drag (Pan Update)]
       |
       +---> Calculate Angular Velocity: theta_dot = dTheta / dt
       +---> Live Modulate Audio: Gain = 0.25 * (|theta_dot| / peak)
       +---> Compute Surface Curl:
       |        kappa(s, t) = sigma * (2*Theta(t)/L) * (1 - s/L)
       |        theta(s, t) = sigma * Theta(t) * [1 - (1 - s/L)^2]
       |
[Pointer Lift (Pan End / Cancel)]
       |
       +---> IMMEDIATE 0ms Audio Cut-off (Rustle terminates instantly)
       |
       +---> Check Threshold: Drag > 26% width OR Flick Velocity > 400 px/s
             |
             +---> [YES]: Smooth Ease-to-Stack (theta -> pi)
             |            Page hits destination stack -> Trigger One-Shot Landing Thump
             |
             +---> [NO] : Elastic Plate Rebound to Origin (theta -> 0)
```

---

## 🖐 Mathematical Formulation

Can be found in developer documentation.
This ensures an isometric developable surface without metric distortion across all fames.
