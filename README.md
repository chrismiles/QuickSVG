QuickSVG
========


## Overview
QuickSVG is a simple SVG parser that has been designed to handle various SVG file formats. 

QuickSVG relies heavily upon CAShapeLayers to properly render it's paths, thus making it easy to work with native layers after parsing. 


###### Supported Elements 
- Shapes
	- rect
	- circle
	- ellipse 
	- path
	- polygon
	- line
	- polyline
- DOM
	- Symbols
	- Groups
	- Refs


#### Basic Usage

```
NSURL *url = [NSURL fileURLWithPath:@"/path/to/file.svg"];
QuickSVG *svg = [QuickSVG svgFromURL:url)];

[self.view addSubview:svg.view];
```


#### Asyncronous Usage

```
- (void)viewDidLoad
{
	[super viewDidLoad];
	
	NSURL *url = [NSURL fileURLWithPath:@"/path/to/file.svg"];
	QuickSVG *svg = [[QuickSVG alloc] initWithDelegate:self];
}

- (void)quickSVG:(QuickSVG *)quickSVG didParseElement:(QuickSVGElement *)element
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view addSubview:element];
    });
}
```



## Testing
A sample application is included to test SVG rendering. Place any sample files in the folder `Sample SVGs` folder to have them automatically loaded in the `RenderingTests` app. Any included subfolders will automatically be nested within the navigation stack.