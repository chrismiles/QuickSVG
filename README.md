QuickSVG
========


#### Overview
QuickSVG is a simple SVG parser that has been designed to handle various SVG file formats.

The 0.1 release currently supports native support for Adobe Illustrator SVG formatting my focusing on rendering all symbol elements. QuickSVG will render all paths grouped within a defined symbol element.   


#### Usage

```
NSURL *url = [NSURL fileURLWithPath:@"/path/to/file.svg"];
QuickSVG *svg = [QuickSVG svgFromURL:url)];

[self.view addSubview:svg.view];
```