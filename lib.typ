// Course notes: the page style, notes that link to each other, and named statements.
// A course's main.typ applies `course`, and each note file starts with `note`.

/// Fonts. The course flake (`lib.mkShell`) puts them on TYPST_FONT_PATHS. Exported so a
/// course's own extensions match the body and headings.
#let sans = "Geist"
#let serif = "IBM Plex Serif"
/// Plex Serif's letterforms with an OpenType MATH table, which Plex Serif lacks.
#let math-font = "IBM Plex Math"
#let mono = "CommitMono-rizesql"

/// Inks. Hierarchy comes from the serif, from space and from these three inks, not from
/// type size.
#let ink = rgb("#171717")
/// Secondary text: proof-step reasons, "Proof.".
#let ink-2 = rgb("#525252")
/// Metadata: tags, sources, backlinks, statement kinds.
#let ink-3 = rgb("#8f8f8f")
#let rule = rgb("#e2e2e2")
#let well = rgb("#f4f4f4")

// Note headings carry this supplement, which tells them apart from section headings in
// the `ref` and `heading` show rules below.
#let _note-supplement = [Note]

// Statement figures share this kind prefix, so the rules below match every kind,
// including ones a course defines with `statement`.
#let _statement-prefix = "statement:"
#let _is-statement(fig) = type(fig.kind) == str and fig.kind.starts-with(_statement-prefix)

// The note a location belongs to: the last `<note>` marker before it.
#let _note-at(loc) = {
  let notes = query(selector(<note>).before(loc))
  if notes.len() > 0 { notes.last().value }
}

// Ink with a faint underline: in a dense paragraph, coloured links read as noise.
#let _ref-link(loc, body) = link(loc, underline(
  stroke: 0.05em + rgb("#c4c4c4"),
  offset: 0.18em,
  body,
))

// `@xor` renders as the note's title and `@def:ots` as the statement's, never as a
// number: numbers mean nothing outside the course PDF. `@xor[xor'ing]` gives other text.
#let _note-ref(it) = {
  let el = it.element
  let name = if el == none {
    none
  } else if el.func() == heading and el.supplement == _note-supplement {
    el.body
  } else if el.func() == figure and _is-statement(el) {
    el.supplement
  }
  if name == none { return it }
  _ref-link(el.location(), if it.supplement == auto { name } else { it.supplement })
}

// Tags link to their entry in `tag-index`; sources are paths or URLs.
#let _properties(tags, source) = {
  let chip(t) = link(label("tag:" + t), box(
    fill: well,
    radius: 0.3em,
    inset: (x: 0.35em),
    outset: (y: 0.2em),
    "#" + t,
  ))
  let sources = if type(source) == str { (source,) } else { source }
  // URLs without the scheme; paths by file name.
  let name(s) = if s.match(regex("^https?://")) != none {
    s.replace(regex("^https?://"), "").trim("/")
  } else { s.split("/").last() }
  let items = tags.map(chip) + sources.map(s => link(s, name(s)))
  if items.len() > 0 {
    block(above: 0.8em, below: 2em, text(size: 0.85em, fill: ink-3, items.join(h(0.6em))))
  }
}

// Notes that reference this one or anything in it (a definition, a lemma), excluding
// itself. Linking to a lemma counts as linking to its note, as block links do in Obsidian.
#let _backlinks(id) = context {
  let sources = query(ref)
    .filter(r => {
      let targets = query(r.target)
      if targets.len() == 0 { return false }
      let target = _note-at(targets.first().location())
      let source = _note-at(r.location())
      target != none and source != none and target.id == id and source.id != id
    })
    .map(r => _note-at(r.location()))
    .dedup(key: n => n.id)
  if sources.len() > 0 {
    set text(size: 0.85em, fill: ink-3)
    block(above: 2em, stroke: (top: 0.5pt + rule), inset: (top: 0.7em), width: 100%)[
      Linked from #h(0.4em) #sources.map(n => link(label(n.id), n.title)).join(", ")
    ]
  }
}

/// A note: a labelled heading, its properties, the body, then the notes that link here.
/// Start every note file with:
///
/// `#show: note.with("otp", "One-time pad", tags: ("crypto",), source: "slides/01-otp.pdf")`
///
/// Link to it from anywhere with `@otp`, or `@otp[the pad]` for other text. A missing
/// id fails the build.
///
/// `id` is a label, and labels share one namespace across the course, so ids must be
/// unique. Pick short kebab-case ones: "xor", "otp", "one-time-security".
#let note(id, title, tags: (), source: (), body) = {
  [#metadata((id: id, title: title, tags: tags))<note>]
  // A reference needs a numbered heading. The numbering renders nothing.
  [#heading(title, numbering: (..) => none, supplement: _note-supplement)#label(id)]
  _properties(tags, source)
  body
  _backlinks(id)
  pagebreak(weak: true)
}

/// Every tag with the notes carrying it. `course` places it at the end: the tag chips
/// under note titles link here.
#let tag-index() = context {
  let notes = query(<note>).map(m => m.value)
  let tags = notes.map(n => n.tags).flatten().dedup().sorted()
  if tags.len() == 0 { return }
  heading[Tags]
  for t in tags {
    [#heading(level: 2, outlined: false)[\##t]#label("tag:" + t)]
    notes.filter(n => t in n.tags).map(n => link(label(n.id), n.title)).join(", ")
  }
}

#let _callout-kinds = (
  note: (title: "Note", color: rgb("#1e66f5")),
  tip: (title: "Tip", color: rgb("#179299")),
  intuition: (title: "Intuition", color: rgb("#40a02b")),
  pitfall: (title: "Pitfall", color: rgb("#d20f39")),
)

/// A tinted box with a coloured title: `#callout("pitfall")[...]`. Kinds: note, tip,
/// intuition, pitfall. `title:` replaces the kind's default title. For a course's own
/// kind, pass a colour and a title: `#callout(rgb("#df8e1d"), title: "Threat")[...]`.
#let callout(kind, title: auto, body) = {
  let k = if type(kind) == color {
    if title == auto { panic("callout: a colour kind needs `title:`") }
    (title: title, color: kind)
  } else {
    _callout-kinds.at(kind, default: none)
  }
  if k == none {
    panic(
      "callout: unknown kind \""
        + kind
        + "\", expected a colour or one of: "
        + _callout-kinds.keys().join(", "),
    )
  }
  block(
    width: 100%,
    fill: k.color.lighten(92%),
    stroke: (left: 0.15em + k.color),
    radius: (right: 0.2em),
    inset: (x: 0.8em, y: 0.6em),
    [#text(fill: k.color, weight: "bold", if title == auto { k.title } else { title }) \
      #body],
  )
}

/// A statement kind: `statement("Lemma")` makes `#lemma(title: "...")[...] <lem:x>`, a
/// grey block with the title on the left and LEMMA on the right. A course adds its own
/// in lib/prelude.typ: `#let attack = statement("Attack")`.
///
/// Statements are figures so that `@lem:x` can reference them. The title is the
/// figure's supplement, which `_note-ref` renders in place of a number; the numbering
/// exists only because references need one, and renders nothing.
#let statement(name) = (title: none, body) => {
  if type(title) != str {
    panic(
      lower(name)
        + ": `title:` is required, as a string: references render it in place of a number",
    )
  }
  let first = title.first()
  figure(
    kind: _statement-prefix + lower(name),
    supplement: title,
    numbering: (..) => none,
    block(width: 100%, fill: well, radius: 0.25em, inset: (x: 0.9em, y: 0.8em), align(
      left,
      {
        grid(
          columns: (1fr, auto),
          align: (left + bottom, right + bottom),
          text(font: serif, weight: "semibold", upper(first) + title.slice(first.len())),
          text(size: 0.75em, fill: ink-3, tracking: 0.06em, upper(name)),
        )
        v(0.6em, weak: true)
        body
      },
    )),
  )
}

/// `#definition(title: "one-time secrecy")[...] <def:ots>`. The title is what
/// `@def:ots` renders, so it has to make sense outside its note.
#let definition = statement("Definition")
#let lemma = statement("Lemma")
#let theorem = statement("Theorem")

/// Ends a proof with a right-aligned square.
#let qed = h(1fr) + $square$

/// The whole course document. In main.typ:
///
/// ```
/// #show: course.with(title: "Network Security", author: "...",
///   bibliography: bibliography("refs.yml"))
/// #include "notes/0x00-intro.typ"
/// ```
///
/// `bibliography` takes the element, not a path: a path here would resolve inside this
/// package. It is placed only once something cites, since an uncited bibliography is an
/// empty page.
#let course(title: none, author: (), bibliography: none, contents: true, body) = {
  set document(title: title, author: author)
  set page(paper: "a4", margin: 2cm, numbering: "1")
  set par(justify: true, leading: 0.7em, spacing: 1.2em)
  set text(font: sans, size: 10pt, fill: ink)
  show math.equation: set text(font: math-font)
  show raw: set text(font: mono)

  // Space carries the hierarchy: a section opens with a wide gap and a hairline.
  show heading: set text(font: serif, weight: "semibold")
  show heading.where(supplement: _note-supplement): it => block(
    below: 0pt,
    text(size: 2em, it.body),
  )
  show heading.where(level: 2): it => block(above: 2.6em, below: 1em, sticky: true, grid(
    columns: (auto, 1fr),
    column-gutter: 0.8em,
    align: horizon,
    text(size: 1.3em, it.body), line(length: 100%, stroke: 0.5pt + rule),
  ))
  show heading.where(level: 3): set text(size: 1.08em)
  show heading.where(level: 3): set block(above: 1.8em, below: 0.8em)

  show ref: _note-ref
  // In a display equation, a reference justifies a step: secondary to the step itself.
  show math.equation.where(block: true): it => {
    show ref: set text(fill: ink-2)
    it
  }
  // Statements stand apart from the prose around them.
  show figure: it => if _is-statement(it) {
    set block(above: 1.2em, below: 1.2em)
    it
  } else { it }
  // `_Proof._` opens a proof; it is a signpost, not content.
  show emph: it => if it.body == [Proof.] {
    text(font: serif, style: "italic", fill: ink-2, it.body)
  } else { it }

  // A fixed indent: the automatic one follows numbering, and note headings are numbered
  // (invisibly) so that `@id` can reference them.
  show outline.entry: it => link(it.element.location(), it.indented(none, it.inner()))
  show outline.entry.where(level: 1): set text(font: serif, weight: "semibold")
  show outline.entry.where(level: 1): set block(above: 1.2em)

  if contents {
    outline(depth: 2, indent: 1em)
    pagebreak()
  }
  body
  tag-index()
  if bibliography != none {
    context if query(cite).len() > 0 { bibliography }
  }
}
