# Custom Numbered Blocks Extension for Quarto

This extension provides user defined custom div classes (environments) that come with numbering, such as theorems, examples, exercises. Numbered blocks can be **cross referenced**.

- By default, the div's text block is enclosed in a collapsible box, similar to quarto callouts. Other **text container types** may be chosen.
- **Groups** of classes can be defined that share appearance and numbering, similar to LaTeX amsthm.
- Shortcuts for **appearances**  of blocks, including container type and properties such as color, can be defined.
- **Lists-of-classes** can be extracted, such as a list of all theorems. It is also possible to generate a list for a group of classes, or a custom collection.

The filter currently supports output formats pdf and html. It aims at similar appearance in both formats, and therefore does not use the LaTeX `amsthm` package, but `tcolorbox`.


![image](https://github.com/ute/custom-numbered-blocks/assets/5145859/8b69f761-fcf8-44fe-b2ee-2626f59548c9)

## Status
Works with Quarto 1.7.

<!-- 🎅🎄An extended version of custom-numbered-blocks is on the way! It will among others allow for different block types. -->

<!--
Setting the number prefix per page/chapter coming soon.  
There may also soon come changes to the yaml-UI for lists-of-classes.  
And documentation will be extended :-)
-->

## News

### v. 0.7.0

The internal mechanism has been virtually completely rewritten. This solves a couple of old issues, introduces new features and opens up for future enhancements and extensions.

Major new features:

  - appearance definitions
  - new text container types for rendering blocks, e.g. `quartothmlike` that gives an appearance similar to quarto theorem divs
 
Issues solved

  - citations not resolved in block titles [issue raised by @ntq2022](https://github.com/ute/custom-numbered-blocks/issues/7#issue-1967404151)
  - enable including the 'label' for the environment in the reference link [suggestion by @dhodge180](https://github.com/ute/custom-numbered-blocks/issues/14#issuecomment-3386057503)

See more in the [example.qmd](https://ute.github.io/custom-numbered-blocks/example.qmd)

<!-- Adapted numbering level according to quarto's two level cross-referencing mechanism from quarto 1.4 onwards that adds a `crossref` key to yaml. 

For books, custom blocks are numbered by chapter by default. For single documents or websites, the numbering is consecutive. This can be changed with the `crossref` yaml key:
```
crossref:
  chapters: true
```
turns on numbering by section (level 1 header) for other documents than books, and setting `crossref.chapter` to `false` in books switches numbering by chapters off.

Number prefix can be overridden by setting a yaml key `numberprefix` to the desired string value. This also works as div-block attribute. -->

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

### Customization

Appearance properties can be set on a per block, per class, or per group basis, and can be collected and reused under the yaml key `appearances`.
(Only the color cannot be changed individually per block with the current implementation.)

#### Options for referencing
The following options can be set on a per group, per class or per block basis:  

- `label` (string): the label (box name) prefix before the block number. Defaults to the class name.
- `reflabel` (string): the prefix before the block number in long cross references. Defaults to `label`
- `listin`: register for a [list-of](#lists-of-listin-version) 


### Change default rendering options

To change the text container that a class is rendered in, use the key `container`. It can be set per class, per group, or per appearance.

The following definition counts Theorems and Propositions separately, and with `quartothmlike` appearance:

``` yaml
custom-numbered-blocks:
  appearances:
    math: 
      container: quartothmlike
  classes:
    Theorem:
      appearance: math
    Proposition:
      appearance: math      
```

The default appearance `foldbox` renders as a collapsible box with title button, similar to quarto callouts. It comes with a small close button bottom right. You can change the following options in yaml or individually in the div specification:

  - `colors` : an array of two hex rgb color codes, for title button color and frame color. `colors: ['#a08080', '#500000']` would give a pink title button and dark red frame.
  - `collapse`: boolean, default `true`. Initial state of the collapsible box.
  - `boxstyle`: set to `foldbox.simple` for a boxed environment without close button. T
  
Two other appearances are provided:

  - `simpletextbox` : a colored text box that is slightly set in, like quote. here you can only change the `colors` option. Only one color is needed.
  - `quartothmlike` has no further options, and mimics the appearance of theorems in quarto.
  

### Groups of classes with joint counter and joint default appearance
Jointly counted block classes are specified by yaml option `groups`. These groups can also have a common default appearance. For each class, option `group` indicates membership. 
 
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

### Controlling numbering depth
Use the `crossref.chapters` key to turn off numbering by Chapter (books) or by Level 1 heading (other documents). 

```yaml
crossref
  chapters: false
```


## Example

Here is the source code for a (not so) minimal example: [example.qmd](https://ute.github.io/custom-numbered-blocks/example.qmd). And here's the rendered [example.html](https://ute.github.io/custom-numbered-blocks/doc/example.html) and [example.pdf](https://ute.github.io/custom-numbered-blocks/doc/example.pdf) 

## Further tips

### Manually changing number prefix, e.g. for appendices in books

In Quarto *book* projects, custom numbered blocks are numbered with chapter number as prefix. You can replace it with a custom prefix by setting the meta key `numberprefix` in the yaml of the chapter's `.qmd` file. This is necessary to avoid restarting the numbering in appendices, see [this issue by @alejandroschuler](https://github.com/ute/custom-numbered-blocks/issues/11).
```yaml
---
numberprefix: "B" 
---
```
The custom prefix can be any string value

For single file Quarto documents, the numbering according to section number can be overridden by setting `numberprefix` option in the header, e.g.
```
# first header {numberprefix="A" #sec-first}
```

## Limitations

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

## Similar quarto extensions

- If you are mainly interested customizable callout boxes, check out James Balamuta's neat and handy extension [custom-callout](https://quarto.thecoatlessprofessor.com/custom-callout/). It allows to define own callout types with custom color and icon in a very simple and consistent way and comes with fantastic documentation.

- Mateus Molina's extension [custom-amsthm-environments](https://github.com/MateusMolina/custom-amsthm-environments) lets you define your own theorem environment types (such as *Problem*) while maintaining the appearance of quarto's built in theorems, because it also uses Latex `amsthm` mechanism. 