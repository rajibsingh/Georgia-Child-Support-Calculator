# Intown Mediation Look And Feel

## Design Goal

The child support calculator should be branded for Intown Mediation and feel like a polished companion to Andrea Knight | Intown Mediation: calm, professional, and authoritative without feeling legalistic or intimidating. The app is for parents making sense of financial information during a stressful family-law process, so the design should prioritize clarity, trust, and easy reading over decoration.

The app should not look like a generic government form or a consumer finance dashboard. It should feel like a mediation practice tool: steady, restrained, human, and precise.

Primary references:

- Website: https://intownmediation.com
- Header image: https://intownmediation.com/wp-content/uploads/2024/05/cropped-3-1.jpg
- Theme stylesheet: https://intownmediation.com/wp-content/themes/panoramic/style.css

## Brand Observations

The website is built around a quiet professional identity:

- A simple wordmark/title treatment: "Andrea Knight | Intown Mediation."
- A clear service line: family mediation with or without attorneys.
- A restrained teal-blue navigation/accent color.
- A pale blue-gray and white photographic header image.
- Thin, light-weight headings.
- Plain, direct language with minimal marketing flourish.
- Square buttons and square input fields rather than pill-shaped controls.
- Navigation and utility text in compact uppercase styling with increased letter spacing.

For the iOS app, borrow the brand language and proportions, but adapt them for a native, task-focused calculator.

## Color Palette

Use a mostly neutral interface with teal-blue accents and soft blue-gray support colors.

### Primary Colors

| Token | Hex | Use |
| --- | --- | --- |
| `IntownTeal` | `#006489` | Primary actions, selected step indicators, key result accents, navigation tint. |
| `IntownTealHover` | `#3F84A4` | Pressed/hover equivalent, secondary emphasized states. |
| `IntownText` | `#58585A` | Primary body text where pure black would feel too harsh. |
| `IntownFieldText` | `#666666` | Form-field text and secondary body copy. |
| `IntownBorder` | `#CCCCCC` | Form borders, dividers, low-emphasis outlines. |
| `IntownSurface` | `#FFFFFF` | Main content surface. |
| `IntownBackground` | `#F5F5F5` | App background, grouped areas, inactive navigation surfaces. |

### Supporting Colors

These come from the site's header image and icon treatment. Use them sparingly as supporting fills, chart tints, and quiet status surfaces.

| Token | Hex | Use |
| --- | --- | --- |
| `MistBlue` | `#E4ECEF` | Soft section backgrounds and read-only result panels. |
| `PaleSky` | `#B2CAD3` | Secondary chart segments or noncritical comparison marks. |
| `BlueGray` | `#56829D` | Secondary accent when the primary teal is too strong. |
| `DeepMenu` | `#272727` | Rare high-contrast overlays or debug/admin surfaces only. |
| `ErrorRed` | `#BA2227` | Validation errors and blocking warnings. |

Avoid bright gradients, purple-blue palettes, heavy beige themes, and decorative color blocks. Color should guide attention, not carry the whole design.

## Typography

The website uses:

- `Cardo` for the site title/brand.
- `Noto Sans` for body text, inputs, and practical UI text.
- Light-weight headings with teal color.

For iOS:

- Use native iOS system fonts for the UI.
- Do not bundle `Cardo` or `Noto Sans` for the first release.
- Echo the website's typography through light headings, spacing, and color rather than custom font files.

Recommended SwiftUI text scale:

| Role | Size | Weight | Notes |
| --- | ---: | --- | --- |
| App title / brand lockup | 28-34 | Light or Regular | Use native iOS font; brand through wording and color. |
| Screen title | 24-28 | Regular | Teal, calm, not oversized. |
| Section title | 18-21 | Semibold | For form groups and result categories. |
| Body | 16-17 | Regular | Default readable copy. |
| Form labels | 15-16 | Medium | Clear, compact, never tiny. |
| Help text | 14-15 | Regular | Gray, concise, available near the field. |
| Result amount | 34-42 | Semibold | The only place where large type should dominate. |
| Table/result detail | 15-17 | Regular or Medium | Prioritize scanning. |

Do not use condensed, overly formal, or decorative legal typography for calculation screens. The app should feel calm and readable before it feels ornamental.

## Layout Principles

Use a simple worksheet flow with generous spacing and strong hierarchy:

- One primary task per screen.
- Clear progress through the calculation steps.
- Full-width content bands or grouped sections, not nested cards.
- Compact explanatory text near complex legal terms.
- Result details arranged for scanning and comparison.
- Stable dimensions for controls and result rows so values changing do not shift the layout.

Prefer native iOS grouped form patterns, but style them with the Intown palette:

- White content surfaces.
- Light gray page background.
- Thin gray dividers.
- Teal selected states.
- Square or lightly rounded controls, maximum 8 px corner radius.

Avoid large marketing-style hero sections. The first screen should begin the calculator experience.

## Components

### Header

Use a compact Intown Mediation-branded app header:

- Brand line: `Intown Mediation`.
- Optional small subtitle: `Guideline estimate for Georgia parents`.
- Teal accent rule or small brand mark.

Do not copy the website's desktop navigation layout. In iOS, use native navigation bars and progress indicators.

### Buttons

Website buttons are square and restrained. App buttons should follow that spirit:

- Primary button: teal fill, white text, 6-8 px radius.
- Secondary button: white or mist background, teal text, thin teal or gray border.
- Destructive or warning actions: red text or red outline, not a large filled red button unless truly destructive.
- Icon buttons should use SF Symbols and clear accessibility labels.

Avoid pill buttons and oversized rounded rectangles.

### Inputs

Use plain, high-legibility inputs:

- White background.
- 1 px gray border or native grouped form boundary.
- Teal focus state.
- Currency fields should use large enough digits for easy review.
- Validation messages should be close to the field and written plainly.

The site uses square input styling; keep iOS fields only lightly rounded.

### Step Indicator

Use a quiet stepper/progress pattern:

- Teal for current/completed steps.
- Pale gray for upcoming steps.
- Labels should be short: `Case`, `Income`, `Adjustments`, `Time`, `Expenses`, `Results`.

Do not make progress indicators visually louder than the form itself.

### Result Summary

The result screen should be the most polished view:

- Primary monthly payment as the main visual anchor.
- Payer and recipient directly below.
- A short "estimate, not court order" disclaimer nearby.
- Expandable calculation trace sections for transparency.
- Teal accents for the final answer, blue-gray for supporting metrics.

Use table-like rows for intermediate values:

- Combined adjusted income.
- Table row used.
- Pro rata shares.
- Parenting time adjustment.
- Additional expenses.
- Deviations and credits.
- Future uninsured healthcare percentages.

## Visual Motifs

The website's header image is a soft blue-gray, sky-like band. In the app, this can inspire:

- A very subtle blue-gray top band on the results screen.
- Mist-blue backgrounds behind read-only result summaries.
- Soft dividers and calm contrast.

Do not use heavy photographic backgrounds inside the calculator. They would reduce legibility and make the app feel less precise.

## Voice And Tone

The writing should mirror the website's direct, plain-spoken tone:

- Clear and useful.
- Calm about stressful topics.
- Transparent about legal limits.
- Avoid hype, sales language, and fear-based warnings.

Use labels like:

- `Monthly gross income`
- `Court ordered parenting time`
- `Child health insurance premium`
- `Work related child care`
- `Estimated monthly payment`

Use help text like:

- `Use the amount paid for the child, not the full family premium if you know the child-specific amount.`
- `This adjustment applies only when parenting time is court ordered.`
- `This estimate is not legal advice or a court order.`

## Progressive Disclosure

The app should include all 2026 calculation adjustments without making the main path feel dense. Keep the standard case flow simple and reveal advanced controls only when needed:

- Use collapsed sections for deviations, credits, other qualified children, and nonstandard healthcare allocations.
- Prefer short "Add..." actions over always-visible empty fields.
- Show a compact summary when an optional adjustment has been added.
- Keep advanced legal explanations in help text or info sheets, not in the main form body.

## Accessibility

Design for parents reading financial and legal information under pressure:

- Support Dynamic Type.
- Keep body text at 16 pt or larger.
- Ensure all teal-on-white and white-on-teal text passes contrast checks.
- Do not rely on color alone for validation or step status.
- Provide VoiceOver labels for all fields, toggles, steppers, and result rows.
- Use large tap targets, at least 44 x 44 pt.

## Implementation Notes

Create a small SwiftUI design system before building full screens:

- `IntownColors`
- `IntownTypography`
- `PrimaryActionButton`
- `SecondaryActionButton`
- `CurrencyField`
- `StepProgressView`
- `ResultMetricRow`
- `ValidationMessage`

Keep these components boring in the best sense: predictable, readable, and easy to test.

## Design Do's And Don'ts

Do:

- Use teal as the primary action and confidence color.
- Use native iOS system fonts for readable forms.
- Use Intown Mediation wording, teal, and spacing for brand continuity rather than custom fonts.
- Keep forms clean, linear, and calm.
- Make final results easy to audit.
- Use square or lightly rounded controls.

Do not:

- Build a landing page before the calculator.
- Use decorative gradients, orbs, or heavy shadows.
- Use tiny legal-form typography.
- Hide important calculation details behind vague summaries.
- Use playful finance-app styling.
- Overuse the header photo or make text sit on busy imagery.
