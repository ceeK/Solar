Pod::Spec.new do |s|
  s.name         = "Solar-dev"
  s.module_name  = "Solar"
  s.version      = "3.0.1"
  s.summary      = "A Swift library for generating Sunrise and Sunset times."
  s.description  = "A Swift library for generating Sunrise and Sunset times. All calculations take place locally without the need for a network request."
  s.homepage     = "http://github.com/ceek/solar"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Chris Howell" => "chris.kevin.howell@gmail.com" }
  s.ios.deployment_target = '9.0'
  s.watchos.deployment_target = '3.0'
  s.tvos.deployment_target = '9.0'
  s.osx.deployment_target = '10.9'
  s.source       = { :git => "https://github.com/ceek/Solar.git", :tag => "#{s.version}" }
  s.source_files  = "Solar/*.{swift}"
  s.requires_arc = true
  s.swift_version = "5.0"
end
