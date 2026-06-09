---
name: Premium Cricket Scorer
colors:
  surface: '#f7f9fc'
  surface-dim: '#d8dadd'
  surface-bright: '#f7f9fc'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f4f7'
  surface-container: '#eceef1'
  surface-container-high: '#e6e8eb'
  surface-container-highest: '#e0e3e6'
  on-surface: '#191c1e'
  on-surface-variant: '#5d3f3c'
  inverse-surface: '#2d3133'
  inverse-on-surface: '#eff1f4'
  outline: '#926f6b'
  outline-variant: '#e7bdb8'
  surface-tint: '#c00014'
  primary: '#ba0013'
  on-primary: '#ffffff'
  primary-container: '#e31e24'
  on-primary-container: '#fffafa'
  inverse-primary: '#ffb4ab'
  secondary: '#575d78'
  on-secondary: '#ffffff'
  secondary-container: '#d8defe'
  on-secondary-container: '#5b627c'
  tertiary: '#006b1b'
  on-tertiary: '#ffffff'
  tertiary-container: '#1d862d'
  on-tertiary-container: '#f5ffef'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdad6'
  primary-fixed-dim: '#ffb4ab'
  on-primary-fixed: '#410002'
  on-primary-fixed-variant: '#93000d'
  secondary-fixed: '#dbe1ff'
  secondary-fixed-dim: '#bfc5e4'
  on-secondary-fixed: '#131b31'
  on-secondary-fixed-variant: '#3f465f'
  tertiary-fixed: '#94f990'
  tertiary-fixed-dim: '#78dc77'
  on-tertiary-fixed: '#002204'
  on-tertiary-fixed-variant: '#005313'
  background: '#f7f9fc'
  on-background: '#191c1e'
  surface-variant: '#e0e3e6'
typography:
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-bold:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.05em
  score-display:
    fontFamily: Plus Jakarta Sans
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.04em
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  container-padding: 20px
  card-gutter: 12px
---

## Brand & Style
The design system is built for a premium, high-performance cricket scoring experience. It targets serious players, league organizers, and enthusiasts who require precision and speed. The visual style is **Corporate / Modern** with a high-energy "Sporty" edge. It utilizes crisp white surfaces against a sophisticated deep navy foundation to create a professional broadcast-quality feel. 

The aesthetic is characterized by intentional whitespace, high-contrast action areas, and a tactile "card-on-canvas" approach that provides clarity during fast-paced match play. It evokes confidence, urgency, and athletic precision.

## Colors
The palette is rooted in the heritage of the sport. **Sporty Red** is the high-energy primary color used for critical actions, highlights, and primary buttons. **Deep Navy** serves as the authoritative grounding color, used for headers and primary text to ensure a premium feel. 

**Active Green** is reserved strictly for positive status indicators, such as "In-Play," successful tosses, or live match connections. The background uses a soft neutral grey (#F5F7FA) to allow the pure white cards and vibrant red accents to pop, reducing eye strain during long sessions under direct sunlight.

## Typography
This design system uses **Plus Jakarta Sans** for headlines to provide a modern, energetic, and slightly rounded geometric feel that remains highly legible. **Inter** is used for all functional body and label text to ensure maximum readability in data-dense scoring environments.

A special `score-display` role is included for primary match statistics (like total runs or overs remaining), emphasizing the "big data" aspect of the sport. All uppercase labels should utilize increased letter-spacing to maintain clarity at small sizes.

## Layout & Spacing
The layout follows a **Fixed Grid** philosophy for mobile devices, centered with a maximum content width of 480px. It utilizes a 4px baseline grid to maintain a tight, rhythmic flow. 

For the scoring interface, cards are grouped with 12px gutters. Large, thumb-friendly tap targets are prioritized, with primary action buttons spanning the full width of the container at the bottom of the viewport. Margins are set to a generous 20px to prevent content from feeling cramped against device edges.

## Elevation & Depth
Depth is achieved through **Tonal Layers** and subtle shadows. The base canvas is the neutral background. Surfaces (cards) are pure white with a very soft, diffused shadow (`0px 4px 20px rgba(26, 33, 56, 0.08)`).

To emphasize priority, the primary scoring buttons and floating action buttons (FABs) utilize a more aggressive shadow with a slight red tint to suggest they sit higher on the Z-axis. Subtle 1px borders in a very light grey (#E2E8F0) are used on secondary cards to provide definition without adding visual noise.

## Shapes
The design system employs a **Rounded** shape language. Standard UI elements like cards and input fields use a 0.5rem (8px) radius. Larger components like the "Start Match" button or primary scoreboard containers use a 1rem (16px) radius to feel more inviting and tactile. This balance of roundedness provides a modern, premium aesthetic that softens the "data-heavy" nature of a scoring app.

## Components

### Buttons
- **Primary:** Sporty Red background, white text, 16px corner radius. Includes a subtle "inner glow" or shadow for tactility.
- **Secondary:** White background, Navy border (1px), Navy text.
- **Quick-Select (Overs/Runs):** Small white pills with Navy text, turning Red when selected.

### Cards
- **Team Cards:** Feature a thick 4px vertical accent bar on the left (Red for Team A, Blue/Navy for Team B) to provide instant visual distinction.
- **Scoring Card:** Centralized, high-contrast card with large numerical displays for "Overs" or "Runs."

### Input Fields
- **Steppers:** Large +/- icons with soft-grey backgrounds to encourage rapid adjustment.
- **Selectors:** Clean, minimal dropdowns with chevron-down icons and clear placeholder text.

### Badges & Icons
- **Status Badges:** Use Active Green for "Live" or "In-Progress."
- **Icons:** High-contrast, 2px stroke-width line icons in Deep Navy. Icons should be paired with text labels in complex scoring menus to ensure no ambiguity.

### Lists
- **Player Lists:** Clean, white rows with subtle dividers. Each row should have a clear "avatar" or "initial circle" for quick identification.