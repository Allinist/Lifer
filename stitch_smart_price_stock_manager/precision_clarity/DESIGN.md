---
name: Precision & Clarity
colors:
  surface: '#fbf8fc'
  surface-dim: '#dbd9dc'
  surface-bright: '#fbf8fc'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f5f3f6'
  surface-container: '#f0edf0'
  surface-container-high: '#eae7ea'
  surface-container-highest: '#e4e2e5'
  on-surface: '#1b1b1e'
  on-surface-variant: '#45464e'
  inverse-surface: '#303033'
  inverse-on-surface: '#f2f0f3'
  outline: '#75777e'
  outline-variant: '#c6c6ce'
  surface-tint: '#525e7f'
  primary: '#182442'
  on-primary: '#ffffff'
  primary-container: '#2e3a59'
  on-primary-container: '#98a4c9'
  inverse-primary: '#bac6ec'
  secondary: '#006a6a'
  on-secondary: '#ffffff'
  secondary-container: '#90efef'
  on-secondary-container: '#006e6e'
  tertiary: '#312300'
  on-tertiary: '#ffffff'
  tertiary-container: '#4a380c'
  on-tertiary-container: '#bca26c'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dae2ff'
  primary-fixed-dim: '#bac6ec'
  on-primary-fixed: '#0d1a38'
  on-primary-fixed-variant: '#3a4666'
  secondary-fixed: '#93f2f2'
  secondary-fixed-dim: '#76d6d5'
  on-secondary-fixed: '#002020'
  on-secondary-fixed-variant: '#004f4f'
  tertiary-fixed: '#fddfa4'
  tertiary-fixed-dim: '#dfc38b'
  on-tertiary-fixed: '#261a00'
  on-tertiary-fixed-variant: '#574417'
  background: '#fbf8fc'
  on-background: '#1b1b1e'
  surface-variant: '#e4e2e5'
typography:
  display-price:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-base:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  data-tabular:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
  label-caps:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  gutter: 16px
  margin-mobile: 16px
  margin-tablet: 24px
---

## Brand & Style
The brand personality is authoritative yet accessible, designed to instill confidence in users managing complex inventory and fluctuating price data. This design system employs a **Corporate/Modern** aesthetic that synthesizes the structured logic of Material Design, the refined legibility of iOS HIG, and the soft, layered depth found in HarmonyOS. 

The visual language focuses on "Data-First" minimalism, where whitespace is used strategically to separate information density. The emotional response should be one of professional reliability—users should feel that their data is secure, organized, and easy to interpret at a glance.

## Colors
This design system utilizes a palette centered on trust and growth. The **Primary Deep Indigo** is the foundation for navigation and primary actions, providing a grounded, professional feel. The **Secondary Teal** is reserved for growth indicators, interactive accents, and "add" actions, symbolizing freshness and inventory movement.

Status colors are vivid to ensure high glanceability:
- **Emerald** for optimal stock levels and price stability.
- **Amber** for low-stock thresholds or price volatility warnings.
- **Vivid Red** for critical stock-outs or expired items.

The background uses a cool-toned light gray to reduce eye strain during long data-entry sessions, while pure white surfaces indicate interactive card elements.

## Typography
**Inter** is selected for its exceptional legibility and systematic feel across mobile platforms. The hierarchy is optimized for numerical data; "Display Price" uses a tighter letter-spacing and heavier weight to make financial figures prominent.

For inventory lists and spreadsheets, the system utilizes **tabular figures** (monospaced numbers) to ensure that columns of digits align perfectly, allowing users to compare stock counts and prices vertically without visual jitter. Labels are occasionally used in uppercase with slight tracking to differentiate metadata from primary body content.

## Layout & Spacing
The design system follows a **fluid grid** model based on an 8pt rhythm, with a 4pt baseline for micro-adjustments. 

On mobile devices, a 4-column layout is used with 16px margins. On larger screens (tablets/foldables), the system expands to an 8 or 12-column grid. Spacing is intentionally generous around "Value Indicators" (prices/stock counts) to prevent the UI from feeling cluttered despite the high density of information. Horizontal padding in cards is strictly 16px to maintain alignment with the global margin.

## Elevation & Depth
This design system uses **Tonal Layers** combined with **Ambient Shadows** to create a sense of organized hierarchy. 

1. **Base Layer:** Background (#F8FAFC) serves as the canvas.
2. **Surface Layer:** White cards (#FFFFFF) sit on the base with a very soft, diffused shadow (Blur: 12px, Y: 4px, Opacity: 4%) to indicate they are interactive.
3. **Overlay Layer:** Modals and dropdowns use a higher elevation with a slightly more pronounced shadow and a 1px neutral stroke to ensure separation.

This "Soft-Layering" approach avoids the heavy drop-shadows of traditional Material Design in favor of the cleaner, flatter appearance seen in modern HarmonyOS and iOS iterations.

## Shapes
A **Rounded** (0.5rem) shape language is applied to primary UI elements to soften the "industrial" feel of data tracking. 

- **Standard Buttons & Inputs:** 8px (0.5rem) corner radius.
- **Cards:** 16px (1rem) corner radius for a modern, containerized look.
- **Status Badges:** Fully pill-shaped (capsule) to distinguish them from interactive buttons.
- **Charts:** Line and Area charts should use "Monotone" or "Basis" interpolation to produce smooth, curved paths rather than jagged angles, mirroring the roundedness of the UI containers.

## Components

### Buttons & Inputs
- **Primary Action:** Solid Deep Indigo with white text.
- **Secondary Action:** Ghost style with Teal borders and text.
- **Inputs:** High-contrast text on white backgrounds with a subtle 1px gray border. On focus, the border transitions to Teal with a soft glow.

### Cards & Lists
- **Inventory Cards:** Features a leading thumbnail or icon, followed by a title/SKU, and a trailing "Quick-View" price. The status badge is positioned in the top right.
- **Lists:** Use thin 1px dividers with 16px inset to separate line items without adding visual bulk.

### Charts
- **Price Trends:** Area charts using a Teal gradient fill (opacity 10% to 0%) under a 2px stroke line. 
- **Tooltips:** Minimalist dark-themed tooltips that appear on tap/hover, displaying precise time and value data.

### Navigation & Status
- **Tab Bar:** Clear, icon-based navigation using a "blurry" backdrop (Glassmorphism) to allow content to peek through while scrolling.
- **Status Badges:** Small, pill-shaped indicators using the status colors defined in the palette. Text inside badges is 10px Bold Caps for maximum clarity at small scales.