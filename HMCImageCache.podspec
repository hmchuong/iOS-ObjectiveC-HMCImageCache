Pod::Spec.new do |s|
  s.name             = 'HMCImageCache'
  s.version          = '0.1.5'
  s.summary          = 'Support caching images balancing between I/O and memory with LRU algorithm'
  s.description      = <<-DESC
HMCImageCache is a utility supporting caching images with balancing between I/O read write and memory usage by LRU (Least recently use) algorithm as well as calculating available memory size. It also support generating UIImage with target size.
                       DESC

  s.homepage         = 'https://github.com/hmchuong/iOS-Objectivec-HMCImageCache'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Chuong M. Huynh' => 'minhchuong.itus@gmail.com' }
  s.source           = { :git => 'https://github.com/hmchuong/iOS-Objectivec-HMCImageCache', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'HMCImageCache/Classes/**/*'

  # s.resource_bundles = {
  #   'HMCImageCache' => ['HMCImageCache/Assets/*.png']
  # }

  s.public_header_files = 'HMCImageCache/Classes/**/*.h'
  s.frameworks = 'UIKit','ImageIO'
  s.dependency 'HMCThreadSafeMutableCollection', '~> 0.1.0'
  s.dependency 'HMCDownloadManager', '~> 0.1.0'
end
