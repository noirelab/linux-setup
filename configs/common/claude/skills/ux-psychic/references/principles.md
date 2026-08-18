# UX-PSYCHIC principle guide

This guide distills fourteen UX ideas. Sections 1–6 are behavioral lenses for flows and decisions. Sections 7–9 are structural lenses for surfaces that display data. Sections 10–12 are perceptual lenses covering whether a surface can be read and acted on at all. Sections 13–14 cover the words and the movement between screens. Treat them all as design hypotheses and lenses, not universal laws or proof of a guaranteed conversion lift.

Concrete default values — type scales, spacing steps, shadow settings, dark-mode adjustments, icon and button sizing, overlay treatments — live in [visual-craft.md](visual-craft.md).

## 1. Smart defaults and decision fatigue

### Use when

- a form opens with several blank fields;
- the user must configure common choices before seeing value;
- most users follow a predictable path;
- context already reveals a likely answer.

### Good patterns

- prefill a country, date range, category, or view from reliable context;
- remember the user's prior non-sensitive choice;
- show a recommended option and explain why;
- provide a useful sample query or starter configuration;
- make the default easy to scan and change.

### Requirements

- Make the default safe for the majority of intended users.
- Keep it reversible before commitment.
- Distinguish a recommendation from a requirement.
- Avoid silently carrying a default into an irreversible action.

### Do not

- preselect payment add-ons, marketing consent, data sharing, destructive actions, or higher-cost plans;
- infer sensitive attributes;
- hide alternatives or make the default difficult to change.

## 2. Goal gradient and honest momentum

### Use when

- onboarding feels long or starts with an empty checklist;
- users cannot tell where they are;
- an earlier action legitimately completed part of the current goal;
- setup is resumable.

### Good patterns

- count account creation as a completed setup step when it truly is one;
- show completed, current, and remaining steps;
- estimate remaining effort conservatively;
- celebrate meaningful milestones without blocking progress;
- restore progress on return.

### Requirements

- Progress must correspond to real completed work.
- Steps must represent user value, not arbitrary product tasks.
- A percentage must be computed consistently.
- Let users skip optional steps without suggesting failure.

### Do not

- invent “20% complete” with no completed work;
- inflate progress early and slow it later;
- add meaningless steps only to manufacture momentum.

## 3. Reciprocity and value before gates

### Use when

- a user supplies input but the result is hidden behind signup;
- a tool can produce a useful preview cheaply;
- the user has not yet learned whether the product solves their problem;
- permissions or contact details are requested before their purpose is clear.

### Good patterns

- show a real preview, score, sample, estimate, or top findings;
- explain what additional value registration unlocks;
- allow exploration with sample data;
- ask to save or continue after the user sees value;
- request only the information needed for the next benefit.

### Requirements

- The preview must be genuinely useful, not a blurred tease.
- Be explicit about what is included now and after commitment.
- Do not imply the user owes the product anything.

### Do not

- hold an already-computed result hostage solely for lead capture;
- use a fake free result that contains no actionable information;
- request broad permissions unrelated to the preview.

## 4. IKEA effect, endowment, and user investment

### Use when

- signup appears before the user can personalize or create anything;
- configuration is central to understanding the product;
- a low-risk draft can exist before account creation;
- preserving work provides a natural reason to register.

### Good patterns

- let the user choose a goal, template, style, or initial configuration;
- create a local or temporary draft before signup;
- show a preview generated from their choices;
- offer registration to save, sync, publish, collaborate, or continue later;
- clearly state how long temporary work is retained.

### Requirements

- Choices must be meaningful and not busywork.
- Preserve work reliably or disclose limitations before effort is spent.
- Allow users to leave without shame or obstruction.
- Keep pre-signup data collection proportionate and private.

### Do not

- manufacture unnecessary labor to exploit sunk cost;
- threaten data loss when the product could safely preserve it;
- make users repeat work after signup.

## 5. Loss aversion and truthful consequence framing

### Use when

- the user may lose unsaved work, coverage, access, backups, or a real benefit;
- an action is destructive or irreversible;
- a subscription or permission change has concrete consequences;
- users routinely misunderstand what “skip,” “delete,” or “continue” means.

### Good patterns

- name the specific item, date, amount, or capability affected;
- explain the consequence and recovery path;
- provide a neutral alternative such as “Continue without backup”;
- use confirmation only when the risk justifies interruption;
- show an undo period when possible.

### Requirements

- The consequence must be real, current, and verifiable.
- Language must be proportionate to the risk.
- The secondary action must remain understandable and usable.

### Do not

- use “I'll risk it,” “No, I don't care,” or similar confirmshaming;
- fabricate urgency, scarcity, files at risk, or deadlines;
- exaggerate a reversible inconvenience into a threat.

## 6. Contrast effect and transparent anchoring

### Use when

- a price or add-on lacks context;
- plans differ in units or billing cadence;
- users need to compare total cost and value;
- a small cost is meaningfully related to a larger purchase.

### Good patterns

- show monthly and annual totals together;
- show a mathematically correct percentage of the related base price;
- normalize units across plans;
- explain what each option includes and excludes;
- place add-ons next to the relevant product while keeping the total visible.

### Requirements

- Compare like with like.
- Show the full payable amount, renewal cadence, taxes or fees when known, and assumptions.
- Make the base reference relevant to the decision.
- Keep “no thanks” or equivalent actions neutral.

### Do not

- use an intentionally absurd decoy solely to make another plan look cheap;
- hide annual cost behind a monthly number;
- show percentages without the base or omit material fees;
- use a crossed-out price that was not a genuine prior price.

## 7. Data drives the form

### Use when

- building or reviewing a dashboard, table, list, log, feed, or detail pane;
- every field has been rendered as plain left-aligned text;
- a screen displays records that differ in state, category, recency, or magnitude;
- data with a strong time dimension sits in a sortable table.

### Good patterns

- render a closed set of values (status, department, plan, severity) as chips;
- right-align numeric and currency columns and use tabular figures so digits align by place value;
- truncate long free text with the full value available on hover or in a detail view;
- shade or de-emphasize rows that are inactive, archived, deactivated, or expired;
- show identity as an avatar plus name so the eye matches faces faster than strings;
- move time-ordered records into a timeline, and put a timeline in a sidebar, drawer, or second column beside the table;
- roll a time dimension up into a chart so the trend is visible without scanning timestamps;
- derive color from the data's meaning — severity, direction, state — and pair it with an icon or label.

### Requirements

- Choose the form from what the data is, then style it; not the reverse.
- Keep one visual encoding per meaning across the whole product.
- Keep the underlying value accessible whenever it is truncated or abbreviated.
- Give charts and rolled-up summaries the same source of truth as the table.

### Do not

- default everything to a table because it is the easiest component to reach for;
- add color, chips, or badges for visual interest when they encode nothing;
- rely on color alone to convey state;
- summarize into a chart in a way that hides outliers the user needs.

## 8. Progressive disclosure and the spectrum of explicitness

### Use when

- a surface is dense and every action competes for the same space;
- a secondary action occupies permanent, prominent real estate;
- a small task sends the user to a whole separate page;
- a first-time user faces a fully loaded interface with no starting point.

### Good patterns

- place the primary action of a surface visible and labeled on arrival;
- put a small, self-contained task in a popover or drawer instead of a route change;
- reveal low-frequency row or cell actions on hover and focus, with a tooltip naming each one;
- collapse rarely used controls into an overflow menu rather than deleting them;
- sequence onboarding as one pointer or checklist item at a time, advancing as the user acts.

### Requirements

- Rank each action by frequency and importance, then assign its explicitness level deliberately.
- Every hover-revealed action needs a keyboard and touch equivalent — hover is not an interaction on either.
- Keep destructive actions confirmable and never the easiest thing to hit by accident.
- Anything a user is expected to find must be discoverable without prior knowledge.

### Do not

- hide an action the task genuinely requires;
- explain the entire product in one modal at first login;
- use disclosure to bury cancellation, export, pricing, consent, or account deletion;
- make a frequent action cost an extra click to keep the interface looking clean.

## 9. The invisible UI layer

### Use when

- specifying or implementing any data-dense surface;
- a design exists only as a populated happy-path frame;
- icon-only controls appear without labels;
- reviewing work that looks finished but has not been used with real data.

### Good patterns

- enumerate the hidden layer explicitly alongside the visible one before building;
- give every icon-only control and ambiguous label a tooltip;
- define empty, first-run, loading, partial, error, and zero-results-after-filtering states separately;
- define hover, focus, selected, active, disabled, and bulk-selection states for rows and cells;
- add quiet affordances that dense data needs: copy-on-hover, a comment or annotation indicator, an expand control;
- cover announcement, upgrade, and permission-denied moments the team will see rarely and users will see once.

### Requirements

- Treat the invisible layer as part of the deliverable, not polish added later.
- Keep focus states visible and keyboard order sensible wherever a hover state exists.
- Write tooltip and empty-state copy in the product's language, saying what to do next.
- Test each state with real data volumes, including one row, zero rows, and very long values.

### Do not

- ship a table specified only in its fully populated state;
- use a tooltip to carry information the user needs in order to act;
- leave an empty state as a bare "No data";
- assume a new feature needs its own page when a drawer, popover, or state covers it.

## 10. Signifiers

### Use when

- users ask how something works, or support answers the same "where do I click" question repeatedly;
- an interface needs instructional copy to explain its own controls;
- items are clickable but look identical to static text;
- selected, active, inactive, and disabled states are indistinguishable.

### Good patterns

- put a container or shared background around related items so grouping is visible, and leave unrelated items outside it;
- mark the selected item in a set with a filled background, and the current page with an active nav treatment;
- gray out and disable together, so anything that looks inactive truly does nothing;
- give buttons a visible press or active state and links a consistent, recognizable treatment;
- add a tooltip wherever an icon or a terse label cannot carry its own meaning;
- keep one signifier meaning one thing across the product.

### Requirements

- Every interactive element must be identifiable as interactive before it is hovered.
- Disabled controls must explain, on hover or focus, what would enable them.
- Never rely on color alone for selection, state, or validity; pair it with shape, weight, icon, or text.
- Focus signifiers must be at least as clear as hover signifiers.

### Do not

- write instructions to compensate for a control that does not look like one;
- style non-interactive elements to look clickable;
- disable a control with no path to enabling it;
- use a different signifier for the same meaning on different screens.

## 11. Perceptual hierarchy

### Use when

- a screen presents every value at the same size, weight, and color;
- users miss the most important number, status, or action on a surface;
- a card or row reads like a spreadsheet rather than a designed unit;
- a layout is technically complete but nothing draws the eye.

### Good patterns

- rank the elements by what the user needs first, then encode the rank with size, weight, position, and color;
- give the primary element early position and the strongest treatment, and reduce everything else so the contrast holds;
- push timestamps, IDs, and metadata smaller, lower, and lighter;
- set a distinguishing value such as price or status apart with alignment or color rather than more size;
- use proximity and containers to group, so spacing carries the relationship;
- show a relationship with an image, icon, or connecting line instead of describing it in words.

### Requirements

- Hierarchy is relative: promoting everything promotes nothing.
- Keep the same rank encoded the same way across repeated units.
- Reductions in size, weight, or color must still meet contrast and minimum-size requirements.
- Heading order in the markup must match the visual hierarchy.

### Do not

- create emphasis with size alone when position or color would do it more quietly;
- give two elements on the same surface equal maximum emphasis;
- rely on an image for meaning without alt text or a text equivalent;
- let decorative contrast override the actual importance of the data.

## 12. Response to every action

### Use when

- a control gives no acknowledgement when clicked, tapped, or focused;
- an action succeeds but nothing on screen changes;
- users repeat an action because they cannot tell whether the first one worked;
- data loads with no indication that anything is happening.

### Good patterns

- give every interactive element default, hover, active, disabled, and where relevant loading states;
- give inputs a focus state, an error state with a specific message near the field, and a warning state where the issue is not blocking;
- confirm outcomes that are otherwise invisible — copy, save, send, apply — with a brief inline confirmation;
- show loading at the granularity of the thing loading, in place, rather than blanking the whole view;
- use a short micro-interaction to carry the confirmation when a static message would be missed;
- keep the response immediate; perceived speed comes from acknowledgement, not completion.

### Requirements

- Acknowledge the input and confirm the outcome; these are two different needs.
- Announce state changes, errors, and completions to assistive technology, not only visually.
- Honor reduced-motion preferences with a non-animated equivalent that conveys the same information.
- Keep an element's dimensions stable across its states so nothing shifts under the cursor.

### Do not

- rely on animation alone to communicate that something succeeded or failed;
- leave a button clickable during a pending request without indicating the pending state;
- replace a specific error with a generic failure message;
- add motion that delays the user's next action for decoration.

## 13. Copy economy

### Use when

- labels describe the mechanism rather than the outcome the user wants;
- a card, row, or section repeats words its heading or container already states;
- a phrase takes four words to say what two would;
- the same concept is named differently in different places.

### Good patterns

- name the action by its result: "Claim rewards" when the button claims rewards, not "Earn tokens";
- drop words the surrounding heading, section, or container already supplies;
- keep one term per concept and use it everywhere;
- put the distinguishing word first so a scanned list is readable from its left edge;
- let a well-chosen icon, unit, or format carry what a word would otherwise repeat;
- read the finished screen aloud as a whole; repetition is audible before it is visible.

### Requirements

- Clarity outranks brevity. Cut only to the point where meaning is still unambiguous.
- Labels for irreversible, paid, or destructive actions stay explicit even when that costs words.
- Shortened visible copy must not remove information assistive technology depends on; use an accessible name that stays complete.
- Copy compression must survive translation and longer languages.

### Do not

- shorten a label into ambiguity to satisfy a word count;
- use internal or technical vocabulary because it is compact;
- rename the same concept across screens for variety;
- let a placeholder, tooltip, or icon replace a label the user needs while acting.

## 14. Continuity between screens

### Use when

- a flow is specified as a set of static screens with nothing said about the moves between them;
- an element appears on two consecutive screens in different places;
- users lose scroll position, filters, selections, or entered values on navigation or back;
- a product is functionally correct but feels disjointed to use.

### Good patterns

- specify transitions alongside states: what carries over, what moves, what the eye should follow;
- let a persisting element move to its new position rather than disappear and reappear;
- preserve scroll position, filters, sort, selection, and unsent input across navigation and return;
- make the origin of a new surface visible — a panel that grows from the control that opened it explains itself;
- spend deliberate motion on the few moments worth remembering, not on every transition;
- keep durations short enough that a returning user never waits on an animation.

### Requirements

- Every transition needs a reduced-motion equivalent that conveys the same relationship without movement.
- Motion must be interruptible; a user acting mid-transition is not an error case.
- Continuity must not fabricate a relationship between things that are not related.
- Preserved state must be visible and clearable, so a returning user is never confused by a filter they forgot.

### Do not

- animate a transition the user will see hundreds of times a day;
- make delight a reason to slow down a frequent path;
- treat motion as a substitute for a hierarchy or signifier that is missing;
- discard user input on back navigation because the screens were designed independently.
