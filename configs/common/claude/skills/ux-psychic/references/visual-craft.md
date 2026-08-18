# UX-PSYCHIC visual craft defaults

Concrete starting values for lenses 10–12. These are defaults for a design that has none, not corrections to a design that already has its own system.

**Precedence:** the product's existing tokens, scale, and design system win. Adopt these values only where nothing is established, and never rewrite a working system to match them.

**Floor:** every value here is subject to contrast, target-size, focus-visibility, and reduced-motion requirements. Any adjustment that would break one of those is wrong regardless of how it looks.

## Typography

- One typeface is enough for almost any product. Pick a well-made sans and stop; this is not where the time goes.
- Large text — display and headings above roughly 32px — tightens: letter-spacing `-2%` to `-3%`, line-height `110%` to `120%`. Body text keeps normal spacing and `140%` to `160%`.
- Marketing pages: at most about six sizes across a wide range.
- Dashboards and dense product UI: about four sizes and two weights, rarely above 24px, because density carries the hierarchy instead of scale.
- Counting is the fastest audit there is. If a screen uses six sizes and four weights, cutting to four and two will improve it more than any other single change.
- When something new needs emphasis, reuse an existing step before adding one. Decimal fractions taking the size of a nearby label is a size reused, not a size added.
- Set large numerals — balances, counters, metrics, table figures — in a monospace or tabular cut of the same family so digits hold their column as values change.
- Never go below the product's minimum readable body size to fit more in; cut content or use disclosure instead.

## Spacing and layout

- Use a 4-point base and keep every value a multiple. The benefit is halvability and consistency, not that any specific number looks better.
- Whitespace does more than a grid. Group related elements tightly and separate groups generously; the spacing itself is hierarchy.
- A common section rhythm: about 32px between sibling elements, less within a group that reads as one unit.
- Column grids earn their place on repeating content — galleries, listings, blogs, card decks — where 12/8/4 across desktop, tablet, and mobile gives predictable responsive behavior. Custom landing sections do not have to sit on them.

## Color

- Start with one primary, usually the brand color. Lighten it for backgrounds and darken it for text to get subtle color into an otherwise flat design.
- Extend that into a ramp once chips, states, charts, and surfaces need consistent steps. Prefer shades and tints of one hue to introducing a second hue.
- Budget roughly 60/30/10: most of the surface neutral, a secondary tone for structure and text, and about a tenth carrying the accent. A screen where the accent dominates is inverted — everything competes and nothing reads as important.
- Accent scarcity is what makes an accent work. Spend it on the few elements that should be noticed first, and let the rest of the interface be quiet.
- Under-using color is its own failure. An interface with no accent anywhere reads as unfinished rather than restrained.
- Semantic colors carry meaning: blue for informational and trust, red for danger and destructive, yellow or amber for warning, green for success. Keep these consistent and do not use them decoratively.
- Color must be purposeful. If removing a color changes nothing about comprehension, it was decoration.
- Pair every semantic color with an icon, label, or shape so meaning survives color-blindness and grayscale.

## Dark mode

- Dark mode is not an inversion. Re-derive it.
- Borders that work in light mode are usually too bright; reduce their contrast against the surface.
- Shadows barely read on dark backgrounds. Convey elevation by making the raised surface lighter than the background.
- Saturated fills — chips, badges, banners — need reduced saturation and brightness; keep the text brighter than the fill so it stays legible.
- Backgrounds are not limited to navy and gray; deep purples, greens, and reds work.
- Re-check contrast after every dark-mode adjustment. Dimming to reduce glare is the most common way to fall below the minimum.

## Shadows

- Most shadows are too strong. Lower the opacity and raise the blur.
- Scale strength with elevation: cards need very little; popovers, dropdowns, and modals sitting above other content need more.
- Combining inner and outer shadows produces tactile, raised controls when that suits the product.
- If the shadow is the first thing noticed, it is wrong.
- Shadows are decoration, not information — never let elevation be the only signal for state or grouping.

## Icons and buttons

- Match icon size to the line-height of the text beside it — 24px text line-height, 24px icon — then tighten the gap. Oversized icons are the usual mistake.
- A nav or sidebar link is a ghost button: no background until hover or focus. Isolated and centered, the same component works as a standalone button.
- Horizontal padding around twice the vertical padding is a reasonable default for button proportion.
- Primary and secondary actions sit side by side with clearly different weight, and the secondary must remain readable — a de-emphasized action is not a hidden one.
- Icon-only buttons need an accessible name and a tooltip, and must still meet minimum touch-target size regardless of icon size.

## Overlays

- Text over an image needs a treatment; raw text on photography is not acceptable at any contrast.
- A full-screen scrim works but flattens the image. A linear gradient from opaque behind the text to transparent over the rest keeps the image visible and the text readable.
- A progressive blur layered under the gradient is a more modern variant of the same idea.
- Verify contrast against the lightest region of the actual image, not against the average or a representative crop.
