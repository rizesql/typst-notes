// The course as one document. A note's links only resolve once it is included here.
#import "lib/prelude.typ": *

#show: course.with(
  title: "Course title",
  author: "Iulian Rizescu",
  bibliography: bibliography("refs.yml"),
)

// Notes in reading order.
#include "concepts/example.typ"
#include "notes/0x00-intro.typ"
