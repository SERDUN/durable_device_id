#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint durable_device_id.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'durable_device_id'
  s.version          = '0.1.0'
  s.summary          = 'A device identifier that survives a reinstall of the app.'
  s.description      = <<-DESC
A device identifier that survives a reinstall of the app.
                       DESC
  s.homepage         = 'https://github.com/SERDUN/durable_device_id'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Dmytro Serdun' => 'dmitriiserdun@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'durable_device_id/Sources/durable_device_id/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'durable_device_id_privacy' => ['durable_device_id/Sources/durable_device_id/PrivacyInfo.xcprivacy']}
end
