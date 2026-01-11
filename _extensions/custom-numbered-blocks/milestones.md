 # What to do next

next steps:

- [x] split: fmt in init
- [x] appearances
  - [x] modify this, to allow title rendering in original format
    - [x] appearances are hierarchical list that starts with format
    - [x] need to sandwich title in beginBlock. This could be more challenging for contributers. But who wants to make their own container. At most a handful of cracks.
    - [x] beginBlock returns **list of pandoc inlines**. Do the same for endBlock
- [x] crossref reorg
- [x] title rendering reorg
- [ ] colors

## Split up in chunks

- [x] split monolith up into parts for each step of processing
- [x] repair bugs due to splitting:
  - [x] fmt not detected -> insert in `cnbx` list
  - [x] clean up code, put this into init
  - [x] titles are not rendered properly. Maybe this is futile because titles will change anyway

## Document

This has to be ongoing

- [ ] landmap for the parts `cnb-1` to `cnb-9`
- [ ] comments in code

New parts:

- [ ] cnb-global
- [ ] cnb-utilities
- [ ] cnb-colors

## Change title rendering: make use of pandoc utilities

do this concurrently with crossref reorganisation
- [x] store title as Inlines `pandoctitle`
- [x] use this stored title for rendering
- [x] concurrently store md version as `mdtitle`, using the new translator function `str_md`

## Simplify rendering containers interface: no use of fmt

This is a big one. Remove looking up format. Let return separate lists for each format, and only insert the one for the current format.

- [x] so far inserted both lists and chose from format
- [x] remove evt. dependency on format by preselecting what to insert. Then use `.render.xxx` instead of `.render[cnbx.fmt].xxx`

## Allow concurrent container typez

This is also a big one

- [x] decide on interface and implement it
- [x] make a template for a simple container, not using details-summary

## Reorganize the whole crossref thing

Also a quite comprehensive one

- [x] no new extra arguments to divs, but store in global list with identifier
- [x] 1. round: crossreferences and identifiers, store as json (json later only for books, now for debugging)
- [ ] for books: register if changes occur and if there are unresolved references
- [x] for monofile document types: json just do not generate it from start
  
## Use brand colors and define own palettes

Do this when the rest is working