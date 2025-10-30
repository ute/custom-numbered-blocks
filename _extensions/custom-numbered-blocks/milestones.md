# What to do next

next steps:

- [ ] split: fmt in init
- [ ] title rendering

## Split up in chunks

- [x] split monolith up into parts for each step of processing
- [ ] repair bugs due to splitting:
  - [x] fmt not detected -> insert in `cnbx` list
  - [ ] clean up code, put this into init
  - [ ] titles are not rendered properly. Maybe this is futile because titles will change anyway

## Document

This has to be ongoing

- [ ] landmap for the parts `cnb-1` to `cnb-9`

## Change title rendering: make use of pandoc utilities

- [ ] store title as Inlines
- [ ] use this stored title for rendering
- [ ] concurrently store md version as `mdtitle`, using the new translator function `deInline`

## Simplify stylez interface: no use of fmt

This is a big one. Remove looking up format. Let return separate lists for each format, and only insert the one for the current format.

## Allow concurrent stylez

This is also a big one

- [ ] make a template for a simple style, not using details-summary
