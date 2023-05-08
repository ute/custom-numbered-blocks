# Custom Numbered Blocks Extension for Quarto

This extension provides user defined custom div classes (environments) that come with numbering, such as theorems, examples, exercises. Numbered blocks can be cross referenced. 

By default, the div's text block is enclosed in a collapsible box, similar to quarto callouts.

The filter supports output formats pdf and html.

## Status

This is still a very preliminary version

## Installing

```bash
quarto add ute/custom-numbered-blocks
```

This will install the extension under the `_extensions` subdirectory.
If you're using version control, you will want to check in this directory.

## Using

Usage is illustrated more comprehensively in `example.qmd`.

### Defining and using a user defined class
To specify a new class of numbered div blocks, `Example`, say, add yaml code:
```yaml
custom-numbered-blocks:
  classes:
    Example: default
```
Use the class in a fenced dive. Title can be provided as a header immediately after div.
```
::: Example
### the best possible example, ever
here is some exemplary text
:::  
```

### Change default options for a class
The default style (and currently only possible style) renders as a collapsible box with title button, similar to quarto callouts. You can change the following options in yaml or individually in the div specification:
  - `colors` : an array of two hex rgb color codes, for title button color and frame color. `colors: [a08080, 500000]` would give a pink title button and dark red frame.
  - `collapse`: boolean, default `true`. Initial state of the collapsible box.
  - `label`: the label to print before the number (string).

### Groups of classes with joint counter and joint default style
Jointly counted block classes are specified by yaml option `groups`. These groups can also have a common default style. For each class, option `group` indicates membership. 
 
**Example**: we want to jointly count theorems, lemmas and propositions, and render boxes  with initially open status, but propositions should be collapsed:
```yaml
custom-numbered-blocks:
  groups:
    thmlike:
      collapse: false
  classes:
    Theorem:
      group: thmlike
    Proposition:
      group: thmlike
      collapse: true
    Lemma:
      group: thmlike                  
```

## Example

Here is the source code for a (not so) minimal example: [example.qmd](example.qmd). And here's the rendered [example.html](doc/example.html) and [example.pdf](doc/example.pdf) 

