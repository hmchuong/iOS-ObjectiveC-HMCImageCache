//
//  HMCImageCache.m
//  HMCImageCache
//
//  Created by chuonghuynh on 8/2/17.
//  Copyright © 2017 Chương M. Huỳnh. All rights reserved.
//

#import "HMCImageCache.h"
#import "NSDate+Extension.h"
#import "HMCSystemHelper.h"
#import "LRUMemoryCache.h"
#import "HMCDownloadManager.h"

@interface HMCImageCache()

@property (strong, nonatomic) NSFileManager *icFileManager;     // File manager
@property (strong, nonatomic) LRUMemoryCache *icMemCache;       // Memory cache
@property (nonatomic) dispatch_queue_t icIOQueue;       // Queue for read/write file serial
@property (strong, nonatomic) NSString *icDirPath;              // Directory path for save file

@end

@implementation HMCImageCache

#pragma mark - Contructors

- (instancetype)init {
    
    self = [super init];
    
    _icMemCache = [[LRUMemoryCache alloc] init];
    [self maximizeMemoryCache];
    
    _icIOQueue = dispatch_queue_create("com.vn.chuonghuynh.HMCImageCache", DISPATCH_QUEUE_SERIAL);
    
    // I/O
    dispatch_async(_icIOQueue, ^{
        // File manager
        _icFileManager = [NSFileManager defaultManager];
        
        // Create directory path
        NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docsPath = [dirPaths objectAtIndex:0];
        _icDirPath = [docsPath stringByAppendingString:@"/com.vn.chuonghuynh.HMCImageCache"];
        
        // Create directory if not exist
        if (![_icFileManager fileExistsAtPath:_icDirPath]) {
            
            [_icFileManager createDirectoryAtPath:_icDirPath
                    withIntermediateDirectories:NO
                                     attributes:nil
                                          error:nil];
        }
    });
    
    // Clear memory cache if mem warning
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(clearMemory)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];
    
    // Delete old files when app terminated
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deleteOldFiles)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
    
    // Maximize memory cache when application enters foreground
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(maximizeMemoryCache)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    // Minimize memory cache when application enters background
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(minimizeMemoryCache)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    return self;
}

#pragma mark - Destructors

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Static methods

+ (id)sharedInstance {
    
    static HMCImageCache *sharedImageCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedImageCache = [[self alloc] init];
    });
    return sharedImageCache;
}

#pragma mark - Public methods

- (void)storeImage:(UIImage *)image withKey:(NSString *)key {
    
    [self storeImageToDisk:image withKey:key];
}

- (UIImage *)imageFromKey:(NSString *)key
               storeToMem:(BOOL)storeToMem {
    
    UIImage *image = [self imageFromMemCacheWithKey:key];
    if (image) {
        return image;
    }
    return [self imageFromDiskWithKey:key storeToMem:storeToMem];
}

- (UIImage *)imageFromKey:(NSString *)key
                 withSize:(CGSize)size {
    
    NSString *thumbnailKey = [NSString stringWithFormat:@"%@-%fx%f",key,size.width,size.height];
    UIImage *image = [self imageFromKey:thumbnailKey storeToMem:YES];
    if (image == nil) {
        image = [self imageFromDiskWithKey:key size:size];
    }
    return image;
}

- (void)removeImageForKey:(NSString *)key {
    
    [self removeImageInMemWithKey:key];
    [self removeImageOnDiskWithKey:key];
}

- (void)removeAllCache {
    
    [self removeAllCacheOnMem];
    [self removeAllCacheOnDisk];
}

#pragma mark - Private methods

/**
 Remove all image in memory cache
 */
- (void)removeAllCacheOnMem {
    
    [_icMemCache removeAllObjects];
}

/**
 Remove all image on disk
 */
- (void)removeAllCacheOnDisk {
    
    dispatch_async(_icIOQueue, ^{
        NSError *error;
        
        // Get all files in directory
        NSArray *files = [_icFileManager contentsOfDirectoryAtPath:_icDirPath
                                                             error:&error];
#if DEBUG
        NSAssert(error != nil, error.debugDescription);
#endif
        
        for (NSString *file in files) {
            // Delete file
            BOOL success = [_icFileManager removeItemAtPath:[NSString stringWithFormat:@"%@/%@", _icDirPath, file] error:&error];
#if DEBUG
            NSAssert(success && error != nil, error.debugDescription);
#endif
            
        }
    });
}

/**
 Store image to disk

 @param image - image to store
 @param key - key of image
 */
- (void)storeImageToDisk:(UIImage *)image
                withKey:(NSString *)key {
    
    NSString *filePath = [self getFilePathFromKey:key];
    NSData *imageData = UIImagePNGRepresentation(image);
    
    // Write to file
    dispatch_async(_icIOQueue, ^{
        
        [imageData writeToFile:filePath
                    atomically:YES];
    });
}

/**
 Store image to memory cache

 @param image - image to store
 @param key - key of image
 */
- (void)storeImageToMem:(UIImage *)image
               withKey:(NSString *)key
                  cost:(NSUInteger)cost{
    
    [_icMemCache setObject:image
                    forKey:key
                      cost:cost];
}

/**
 Load image from disk

 @param key - key of image to load
 @param storeToMem - want to store in memory
 @return image from disk
 */
- (UIImage *)imageFromDiskWithKey:(NSString *)key
                       storeToMem:(BOOL)storeToMem {
    
    NSString *filePath = [self getFilePathFromKey:key];
    
    // Read image data from disk
    NSData __block *imageData;
    dispatch_sync(_icIOQueue, ^{
        imageData = [NSData dataWithContentsOfFile:filePath];
    });
    
    // If has image fixed key, store image to mem cache
    UIImage *image = [UIImage imageWithData:imageData];
    if (storeToMem && image) {
        
        [self storeImageToMem:image
                       withKey:key
                         cost:[imageData length]];
    }
    
    return image;
}

/**
 Image from disk with key and size

 @param key key of image
 @param size size of image
 @return image in size
 */
- (UIImage *)imageFromDiskWithKey:(NSString *)key
                             size:(CGSize)size {
    
    NSURL *filePath = [NSURL fileURLWithPath:[self getFilePathFromKey:key]];
    
    UIImage *image = [self resizeImageAtPath:filePath maxSize:(size.height > size.width) ? size.height : size.width];
    if (image) {
        
        [self storeImage:image
                 withKey:[NSString stringWithFormat:@"%@-%fx%f",key,size.width,size.height]];
    }
    
    return image;
}

/**
 Load image from memory cache with key

 @param key - key of image to load
 @return image in memory cache
 */
- (UIImage *)imageFromMemCacheWithKey:(NSString *)key {
    
    return [_icMemCache objectForKey:key];
}

/**
 Get absolute file path from key on disk

 @param key - key to get
 @return absolute file path
 */
- (NSString *)getFilePathFromKey:(NSString *)key {
    
    NSString __block *databasePath;
    
    // Need to wait until directory is created
    dispatch_sync(_icIOQueue, ^{
        databasePath = [[NSString alloc] initWithString: [_icDirPath stringByAppendingPathComponent:key]];
    });
    
    return databasePath;
}

/**
 Remove image in memory cache

 @param key - key object to remove
 */
- (void)removeImageInMemWithKey:(NSString *)key {
    
    [_icMemCache removeObjectForKey:key];
}

/**
 Remove image on disk

 @param key - key of object to remove
 */
- (void)removeImageOnDiskWithKey:(NSString *)key {
    
    dispatch_async(_icIOQueue, ^{
        NSError *error;
        [_icFileManager removeItemAtPath:[self getFilePathFromKey:key] error:&error];
        
#if DEBUG
        NSAssert(!error, error.debugDescription);
#endif
        
    });
}

/**
 Clear all memory cache
 */
- (void)clearMemory {
    
    [_icMemCache removeAllObjects];
}

/**
 Delete old files on disk
 */
- (void)deleteOldFiles {
    
    dispatch_async(_icIOQueue, ^{
        NSError *error;
        
        // Get all files on disk
        NSArray *files = [_icFileManager contentsOfDirectoryAtPath:_icDirPath error:&error];
        
#if DEBUG
        NSAssert(!error, error.debugDescription);
#endif
        
        for (NSString *file in files) {
            NSString *path = [NSString stringWithFormat:@"%@/%@", _icDirPath, file];
            
            // Get modifidation date
            NSDictionary *attributes = [_icFileManager attributesOfItemAtPath:path error:nil];
            NSDate *lastModifiedDate = [attributes fileModificationDate];
            
            // Skip if last modified date is in threshold
            NSDate *today = [NSDate date];
            if ([NSDate daysBetweenDate:lastModifiedDate andDate:today] <= IMAGE_CACHE_EXPIRATION_DAYS) {
                continue;
            }
            
            // Delete file
            BOOL success = [_icFileManager removeItemAtPath:path error:&error];
            
#if DEBUG
            NSAssert(!success || error, error.debugDescription);
#endif
            
        }
    });
}

/**
 Set memory cache threshold

 @param ratio - proportion of free memory to limit
 */
- (void)setMemoryThreshold:(float)ratio {
    
    unsigned long freeMemory = [HMCSystemHelper getFreeMemory];
    
    if (freeMemory == 0) {  // Cannot get memory info
        return;
    }
    
    unsigned long threshold = floor(freeMemory * ratio);
    
    [self.icMemCache setTotalCostLimit:threshold];
}

/**
 Minimize memory cache
 */
- (void)minimizeMemoryCache {
    
    [self setMemoryThreshold:MINIMUM_MEMORY_RATIO];
}

/**
 Maximize memory cache
 */
- (void)maximizeMemoryCache {
    
    [self setMemoryThreshold:MAXIMUM_MEMORY_RATIO];
}

/**
 Resize image at path with size

 @param imagePath image path
 @param maxSize max size of image
 @return image after resize
 */
- (UIImage *)resizeImageAtPath:(NSURL *)imagePath maxSize:(CGFloat)maxSize {
    
    if (maxSize <= 0) {
        return nil;
    }
    
    // Create the image source
    CGImageSourceRef src = CGImageSourceCreateWithURL((__bridge CFURLRef) imagePath, NULL);
    
    if (src == nil) {
        return nil;
    }
    
    // Create thumbnail options
    CFDictionaryRef options = (__bridge CFDictionaryRef) @{
                                                           (id) kCGImageSourceCreateThumbnailWithTransform : @YES,
                                                           (id) kCGImageSourceCreateThumbnailFromImageAlways : @YES,
                                                           (id) kCGImageSourceThumbnailMaxPixelSize : @(maxSize)
                                                           };
    
    // Generate the thumbnail
    CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex(src, 0, options);
    CFRelease(src);
    
    // Write the thumbnail at path
    UIImage *image = [UIImage imageWithCGImage:thumbnail];
    
    return image;
}

/**
 Sanitize filename string

 @param fileName filename to santinize
 @return santinized filename
 */
- (NSString *)sanitizeFileNameString:(NSString *)fileName {
    
    NSCharacterSet* illegalFileNameCharacters = [NSCharacterSet characterSetWithCharactersInString:@"/\\?%*|\"<>"];
    return [[fileName componentsSeparatedByCharactersInSet:illegalFileNameCharacters] componentsJoinedByString:@""];
}

- (void)imageFromURL:(NSURL *)url
      withTargetSize:(CGSize)size
          completion:(void (^)(UIImage *, NSString *))completionCallback
       callbackQueue:(dispatch_queue_t)queue {
    
    // Check existed file
    NSString *key = [self sanitizeFileNameString:url.absoluteString];
    NSString *thumbnailKey = [NSString stringWithFormat:@"%@-%fx%f",key,size.width,size.height];
    
    UIImage *__block result = [self imageFromKey:key withSize:size];
    
    if (result != nil) {
        dispatch_async(queue, ^{
            completionCallback(result, thumbnailKey);
        });
    } else{
        
        // Download image
        [HMCDownloadManager.sharedBackgroundManager startDownloadFromURL:url progressBlock:^(NSURL *sourceUrl, NSString *identifier, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
            
        } destination:^NSURL *(NSURL *sourceUrl, NSString *identifier) {
            return [NSURL fileURLWithPath:[self getFilePathFromKey:key]];
        } finishBlock:^(NSURL *sourceUrl, NSString *identifier, NSURL *fileLocation, NSError *error) {
            result = [self imageFromKey:key withSize:size];
            completionCallback(result, thumbnailKey);
        } queue:queue];
        
    }
}

@end
