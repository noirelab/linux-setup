# UX-PSYCHIC visual craft

Two parts with different authority.

- **Floor** — mechanics that decide whether a surface can be read and operated. Always applies, whatever the style. A design that breaks the floor is wrong regardless of how it looks.
- **Defaults** — starting values for a product that has no visual direction at all. They are deliberately plain. They never override a direction that exists or is being chosen: the product's tokens, a brief, a reference, or a design skill the user picked. Never use them to pick the look of a new design; that is how every result ends up looking the same.

## Floor

### Legibility

- Body and placeholder text ≥4.5:1 against its actual background, large text and essential icons ≥3:1. Re-check after every dark-mode or dimming adjustment; dimming to reduce glare is the most common way to fall below.
- Text over an image always gets a treatment (scrim, gradient, or progressive blur). Verify contrast against the lightest region of the actual image, not an average.
- Never go below the product's minimum readable body size to fit more in; cut content or use disclosure.
- Numerals that change or align — balances, counters, metrics, table figures — use tabular figures (`font-variant-numeric: tabular-nums`) so digits hold their column.

### Meaning

- Semantic colors stay consistent and are never decorative, and each is paired with an icon, label, or shape so meaning survives color-blindness and grayscale.
- Shadows and elevation never carry state or grouping alone.

### Operability

- Touch targets meet the minimum size regardless of icon size. Icon-only buttons have an accessible name and a tooltip.
- A de-emphasized secondary action stays readable; de-emphasized is not hidden.
- Focus is visible on every interactive element.

### Radius and optical alignment

- Nested rounded shapes are concentric: inner radius = outer radius − the padding between them. A button with 8px padding inside a 16px-radius card gets an 8px radius; equal radii make the gap pinch at the corners. If the result is zero or negative, use a square inner corner.
- Geometric centering is a starting point, not the answer. Shapes with uneven visual mass need a manual nudge: a play triangle shifts toward its point, a chevron or arrow beside text shifts toward its tip, and a circle or triangle sits slightly larger than a square to look the same size.
- Text in a button or badge is centered on the cap height, not the full line box; when a font's metrics push it off, correct with padding or `text-box-trim`, not one-off margins per instance.
- Make these corrections once, in the component, so every instance inherits them.

## Defaults

Use only when nothing above them exists. Any committed direction — including an unusual one — wins.

### Typography

- One well-made sans is enough when there is no reason for more.
- Display text above roughly 32px tightens: letter-spacing `-2%` to `-3%`, line-height `110%` to `120%`. Body keeps `140%` to `160%`.
- Dense product UI: about four sizes and two weights, rarely above 24px. Marketing: at most about six sizes.
- Counting is the fastest audit: six sizes and four weights cut to four and two usually improves more than any other single change. Reuse an existing step before adding one.

### Spacing and layout

- A 4-point base, every value a multiple, for halvability and consistency.
- Group related elements tightly and separate groups generously; spacing itself is hierarchy.
- Column grids earn their place on repeating content (galleries, listings, card decks); custom sections do not have to sit on them.

### Color

- Start from one primary; lighten for backgrounds, darken for text.
- Roughly 60/30/10 neutral/secondary/accent. Accent scarcity is what makes an accent work, but no accent anywhere reads as unfinished.
- If removing a color changes nothing about comprehension, it was decoration.

### Dark mode

- Re-derive, do not invert. Lower border contrast, convey elevation with lighter surfaces instead of shadows, desaturate fills and keep text brighter than them.

### Shadows

- Lower opacity, higher blur, strength scaled to elevation. If the shadow is the first thing noticed, it is too strong.

### Icons and buttons

- Icon size matches the line-height of adjacent text; oversized icons are the usual mistake.
- Horizontal padding about twice the vertical.
- A nav link is a ghost button: no background until hover or focus.
