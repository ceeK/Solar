#
#  Be sure to run `pod spec lint Solar.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name         = "Solar"
  s.version      = "1.0.0"
  s.summary      = "A Swift library for generating Sunrise and Sunset times."
  s.description  = "A Swift library for generating Sunrise and Sunset times. All processing takes place locally without the need for a network request."
  s.homepage     = "http://github.com/ceek/solar"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Chris Howell" => "chris.kevin.howell@gmail.com" }
  s.platform     = :ios
  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '9.0'
  s.source       = { :git => "https://github.com/ceek/Solar.git", :tag => "#{s.version}" }
  s.source_files  = "Solar/*.{swift}"
  s.requires_arc = true
end
