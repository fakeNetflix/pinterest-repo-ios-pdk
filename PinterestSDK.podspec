#
# Be sure to run `pod lib lint PinterestSDK.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "PinterestSDK"
  s.version          = "1.0.1"
  s.summary          = "An SDK for doing Pinteresting things."
  s.description      = <<-DESC
                       An SDK for interacting with Pinterest.
                       DESC
  s.homepage         = "https://github.com/Pinterest/iOS-PDK"
  s.license          = 'MIT'
  s.author           = { "Ricky Cancro" => "ricky@pinterest.com", "Garrett Moon" => "garrett@pinterest.com" }
  s.source           = { :git => "https://github.com/pinterest/ios-pdk.git", :tag => s.version.to_s }

  s.ios.deployment_target = '7.1'
  s.osx.deployment_target = '10.9'
  s.requires_arc = true
  s.ios.weak_frameworks = 'SafariServices'

  s.public_header_files = 'Pod/Classes/*.h'
  s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'SSKeychain'
end
