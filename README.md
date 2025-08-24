# Custom Numbered Blocks Extension for Quarto

This extension provides user defined custom div classes (environments) that come with numbering, such as theorems, examples, exercises. Numbered blocks can be cross referenced. 

- By default, the div's text block is enclosed in a collapsible box, similar to quarto callouts.
- Groups of classes can be defined that share style and numbering.
- Lists-of-classes can be extracted, such as a list of all theorems. It is also possible to generate a list for a group of classes.

The filter supports output formats pdf and html.


![image](https://github.com/ute/custom-numbered-blocks/assets/5145859/8b69f761-fcf8-44fe-b2ee-2626f59548c9)

## Status
Works with Quarto 1.7.

Setting the number prefix per page/chapter coming soon.  
There may also soon come changes to the yaml-UI for lists-of-classes.  
And documentation will be extended :-)

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
The default style renders as a collapsible box with title button, similar to quarto callouts. It comes with a small close button bottom right. You can change the following options in yaml or individually in the div specification:
  - `colors` : an array of two hex rgb color codes, for title button color and frame color. `colors: [a08080, 500000]` would give a pink title button and dark red frame.
  - `collapse`: boolean, default `true`. Initial state of the collapsible box.
  - `label`: the label to print before the number (string).
  - `boxstyle`: set to `foldbox.simple` for a boxed environment without close button. There will quite likely come more options in a future version.
  - `listin`: register for a [list-of](#lists-of-listin-version) 

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

### Lists-of ("listin" version)
To generate a list of all divs belonging to a class, `Example`, say, add key listin to the class and give the name of the list. The same can be done for groups of classes. This will produce a file `list-of-`name`.qmd` that contains headers and references to the respective blocks. The following code will generage files `list-of-allthingsmath.qmd` and `list-of-examples.qmd`:

```yaml
custom-numbered-blocks
  groups:
    thmlike:
      collapse: false
      listin: [allthingsmath]
    Example:
      listin: [examples, allthingsmath] 
```

## Example

Here is the source code for a (not so) minimal example: [example.qmd](https://ute.github.io/custom-numbered-blocks/example.qmd). And here's the rendered [example.html](https://ute.github.io/custom-numbered-blocks/doc/example.html) and [example.pdf](https://ute.github.io/custom-numbered-blocks/doc/example.pdf) 

## Further tips

### Manually changing number prefix, e.g. for appendices in books

In Quarto *book* projects, custom numbered blocks are numbered with chapter number as prefix. You can replace it with a custom prefix by setting the meta key `chapno` in the yaml of the chapter's `.qmd` file. This is necessary to avoid restarting the numbering in appendices, see [this issue by @alejandroschuler](https://github.com/ute/custom-numbered-blocks/issues/11).
```yaml
---
chapno: "B" 
---
```
The custom prefix can be any string value

For single file Quarto documents, the numbering according to section number can be overridden by setting `secno` option in the header, e.g.
```
# first header {secno="A" #sec-first}
```

## Limitations
- References to bibliography in the title are not resolved, see [this issue by ntq2022](https://github.com/ute/custom-numbered-blocks/issues/7). This is due to the sequence of processing references. Pull requests are welcome - I am not sure
  if I will have time to dig into this in the nearer future.
- Cross-reference labels that are interpretable for Quarto, such as labels starting with `thm-` or `fig-`, cannot be used with this extension, since they will be processed by Quarto. This results in unexpected output, see [this issue by gyu-eun-lee](https://github.com/ute/custom-numbered-blocks/issues/8).
  
## Workarounds and precautions to avoid clashes with other extensions
- If you use [parse-latex](https://github.com/tarleb/parse-latex), make sure that custom-numbered-blocks comes first in the filter pipeline to process LaTeX references (`\ref`).
- Further headers within custom numbered blocks will mess up indentation of paragraphs following that block. To avoid that, include headers in a div, for example
  ```markdown
  ::: {.myblock}
  ### heading of my custom block
  blabla
  
  ::::{}
  ### new header
  ::::
  other stuff
  ```
