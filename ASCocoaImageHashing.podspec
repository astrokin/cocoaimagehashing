Pod::Spec.new do |s|
  s.name             = 'ASCocoaImageHashing'
  s.version          = '2.0.0'
  s.summary          = 'CocoaImageHashing is a framework for perceptual image hashing'

  s.description      = <<-DESC
    A perceptual hash is a fingerprint of a multimedia file derived from various features from its content.
    Unlike cryptographic hash functions which rely on the avalanche effect of small changes in input 
    leading to drastic changes in the output, perceptual hashes are 'close' to one another 
    if the features are similar.
  DESC

  s.homepage         = 'https://github.com/ameingast/cocoaimagehashing'
  s.license          = { :type => 'BSD3', :file => 'LICENSE' }
  s.authors          = { 'Andreas Meingast' => 'ameingast@gmail.com' }

  s.source           = { :git => 'https://github.com/astrokin/cocoaimagehashing.git', :tag => s.version }

  s.platforms        = { :ios => '9.0' }

  s.requires_arc     = true

  s.frameworks       = [ 'Foundation' ]

  s.source_files     = 'CocoaImageHashing/*.{h,m}'
  s.public_header_files = [
    'CocoaImageHashing/CocoaImageHashing.h',
    'CocoaImageHashing/OSTypes.h',
    'CocoaImageHashing/OSImageHashing.h'
  ]

  s.ios.frameworks   = [ 'UIKit' ]
end