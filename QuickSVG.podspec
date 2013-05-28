Pod::Spec.new do |s|
  s.name         = "QuickSVG"
  s.version      = "0.1"
  s.summary      = "Beautifully simple SVG integration with iOS."
  s.homepage     = "https://github.com/quickcue/QuickSVG"
  s.author       = { "Matt Newberry" => "mattnewberry@quickcue.com" }
  s.license      = 'MIT'

  s.ios.deployment_target = '5.0'

  s.source       = { :git => "https://github.com/quickcue/QuickSVG.git", :tag => '0.1' }
  s.source_files = 'QuickSVG/*.{h,m}'

  s.requires_arc = true
end