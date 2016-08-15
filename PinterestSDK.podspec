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
  s.version          = "1.0.2"
  s.summary          = "An SDK for doing Pinteresting things."
  s.description      = <<-DESC
                       An SDK for interacting with Pinterest.
                       DESC
  s.homepage         = "https://github.com/Pinterest/iOS-PDK"
  s.license          = 'MIT'
  s.author           = { "Ricky Cancro" => "ricky@pinterest.com", "Garrett Moon" => "garrett@pinterest.com" }
  s.source           = { :git => "https://github.com/pinterest/ios-pdk.git", :tag => s.version.to_s }

  s.ios.deployment_target = '7.0'
  s.requires_arc = true

  s.weak_frameworks = 'SafariServices'

  s.source_files = 'Pod/Classes/*.{h,m}'

  s.dependency 'AFNetworking', '~> 3.0'
  s.dependency 'SAMKeychain'
end
