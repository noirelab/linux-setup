# UX-PSYCHIC audit scorecard

Use this scorecard for audit mode or before selecting an implementation target.

## Scoring

Score each dimension from 0 to 3:

- **0 — harmful or absent:** creates major friction, confusion, coercion, or accessibility risk.
- **1 — weak:** partially addressed but likely to cause hesitation or abandonment.
- **2 — functional:** adequate with clear room for improvement.
- **3 — strong:** clear, efficient, trustworthy, accessible, and well matched to the user goal.

Do not add scores into a false scientific total. Use them to expose weak areas and compare revisions.

## Dimensions

### Value clarity

- Is the next meaningful benefit obvious?
- Can the user understand the outcome before committing?
- Does the CTA describe the actual result?

### Decision load

- How many decisions are visible at once?
- Are optional choices deferred?
- Are safe defaults or recommendations available?

### Progress and orientation

- Does the user know where they are, what is complete, and what remains?
- Is progress accurate?
- Can they resume without losing work?

### Trust and exchange

- Does the product give enough value before requesting data, registration, payment, or permissions?
- Is the purpose of each request clear?
- Are privacy and retention expectations understandable?

### Investment and continuity

- Can users create or personalize something meaningful?
- Is their work preserved?
- Is signup positioned as saving or extending real value rather than unlocking a hostage result?

### Consequence clarity

- Are destructive, paid, or irreversible consequences specific and proportionate?
- Are alternatives and recovery paths clear?
- Is the copy free of threats and confirmshaming?

### Price and comparison integrity

- Are totals, cadence, units, fees, renewal, and assumptions visible?
- Are comparisons relevant and mathematically accurate?
- Are add-ons and consent unselected by default?

### Error recovery

- Are errors explained near the source?
- Are user values preserved?
- Is there a clear retry, undo, back, or support path?

### Accessibility

- Are labels, semantics, focus, keyboard order, target size, contrast, and reduced motion handled?
- Is meaning independent of color alone?
- Are loading and validation updates announced appropriately?

### Autonomy

- Can users decline, cancel, leave, or change choices without obstruction?
- Are primary and secondary actions visually honest?
- Is the interface free from fabricated urgency or pressure?

## Finding format

For each important finding, record:

- **Location:** screen, route, component, or state.
- **Evidence:** observed UI/code behavior or available data.
- **Hesitation:** cognitive, mechanical, emotional, informational, or accessibility.
- **Principle:** one or more UX-PSYCHIC lenses.
- **Recommendation:** concrete change.
- **Expected outcome:** user and business behavior to test.
- **Confidence:** low, medium, or high, with reason.
- **Effort:** small, medium, or large.
- **Risk:** dark-pattern, accessibility, privacy, technical, or none identified.
- **Metric:** event or user outcome that would validate the hypothesis.

## Priority rule

Prioritize findings that:

1. block the primary task or meaningful value;
2. create accidental purchases, privacy exposure, data loss, or accessibility exclusion;
3. affect a high-frequency step;
4. can be improved safely with limited implementation risk;
5. can be measured without invasive tracking.
