
Pod::Spec.new do |s|

  s.name         = "Loader"
  s.version      = "1.0.0"
  s.summary      = "Add a facebook news feed style animation for your placeholder views"
  s.homepage     = "https://github.com/samhann/Loader.swift"
  s.license      = "MIT"
  s.author       = { "samhann" => "" }
  s.platform     = :ios,'8.0'
  s.source       = { :git => "https://github.com/samhann/Loader.swift.git", :tag => "#{s.version}" }
  s.source_files  = "Classes/**/*.swift"
  s.framework  = "UIKit"
  s.requires_arc = true
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '3.0' }
end
