source 'https://github.com/CocoaPods/Specs.git'
use_frameworks!
platform :ios, '9.0'

def basic_pods
pod 'AFNetworking', '~> 4.0.1' 
pod 'GoogleAnalytics'
pod 'NSString_stripHtml'
pod 'BlocksKit'
pod 'NSString-UrlEncode'
pod 'Fabric'
pod 'Crashlytics'
end

target 'Shadertoy' do
basic_pods
end

target 'Shadertoy_debug' do
basic_pods
pod 'fishhook'
end
