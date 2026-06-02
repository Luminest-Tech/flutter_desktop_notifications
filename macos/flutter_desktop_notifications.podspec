#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_desktop_notifications'
  s.version          = '1.1.0'
  s.summary          = 'macOS implementation of flutter_desktop_notifications.'
  s.description      = <<-DESC
Native desktop notifications for Flutter. This pod is the macOS implementation,
built on UNUserNotificationCenter.
                       DESC
  s.homepage         = 'https://github.com/Luminest-Tech/flutter_desktop_notifications'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Luminest' => 'shrimp.coctails@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.14'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
