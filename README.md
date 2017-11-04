# HMCImageCache

[![Build Status](https://travis-ci.org/hmchuong/iOS-ObjectiveC-HMCImageCache.svg?branch=master)](https://travis-ci.org/hmchuong/iOS-ObjectiveC-HMCImageCache)
[![Version](https://img.shields.io/cocoapods/v/HMCImageCache.svg?style=flat)](http://cocoapods.org/pods/HMCImageCache)
[![License](https://img.shields.io/cocoapods/l/HMCImageCache.svg?style=flat)](http://cocoapods.org/pods/HMCImageCache)
[![Platform](https://img.shields.io/cocoapods/p/HMCImageCache.svg?style=flat)](http://cocoapods.org/pods/HMCImageCache)

## Component Libraries
[HMCThreadSafeMutableCollection](http://cocoapods.org/pods/HMCThreadSafeMutableCollection) provides thread safe array and dictionary  
[HMCDownloadManager](http://cocoapods.org/pods/HMCDownloadManager) provides APIs for downloading image from URL
## Requirements
- iOS 8.0+
- Xcode 8.3+

## Features
- [x] Caching image on disk
- [x] Caching image on memory
- [x] Balancing I/O read write and memory usage
- [x] Auto adjusting memory usage based on avaiable memory *(5% of available mem in background, 80% of available mem in foreground)* 
- [x] Release memory by LRU algorithm
- [x] Auto remove unsued cache files on disk after 30 days 
- [x] Get image from url with target size
- [x] Set UIImageView with image from URL
- [x] Set UIButton with image from URL

## Installation

HMCImageCache is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'HMCImageCache'
```
## Usage

### Singleton object
To get image caching instance:
```ObjectiveC
HMCImageCache *imageCache = [HMCImageCache sharedInstance];
```

### To store image to cache
```ObjectiveC
UIImage *image = ...;
NSString *identifier = ...;
[imageCache storeImage:image withKey:identifier];
```

### To get origin image from cache
```ObjectiveC
image = [imageCache imageFromKey:identifier storeToMem:YES];  // storeToMem: do you want image store to memory
```

### To get image with target size
```ObjectiveC
CGSize size = CGSizeMake(300,400); // Image with size 300px x 400 px
image = [imageCache imageFromKey:identifier withSize:size];
```

### To get image from URL
```ObjectiveC
[imageCache imageFromURL:url
          withTargetSize:CGSizeMake(300,400)
              completion:^(UIImage *image){
                  // do something with image
              }
           callbackQueue:dispatch_get_main_queue()];
```

### To set image to UIImageView from URL
```ObjectiveC
NSURL *url;
UIImageView *imageView;
[imageView HMCSetImageFromURL:url];
```

### To set image to UIButton from URL
```ObjectiveC
NSURL *url;
UIButton *button;
[button HMCSetImageFromURL:url forState: UIControlStateNormal];
```

### To remove an image from cache
```ObjectiveC
[imageCache removeImageForKey:identifier];
```

### To remove all images from cache
```ObjectiveC
[imageCache removeAllCache];
```

## Author

chuonghuynh, minhchuong.itus@gmail.com

## License

HMCImageCache is available under the MIT license. See the LICENSE file for more info.
