//
//  XANPDFScrollView.m
//  XANPDFScrollView
//
//  Created by Chen Xian'an on 12/27/10.
//  Copyright 2010 lazyapps.com. All rights reserved.
//

#import "XANPDFScrollView.h"
#import "XANPDFTiledView.h"

static const NSInteger MARGIN = 2;
static const unsigned char EPSILON = 2;
static const NSInteger THRESHOLD = 8;
static const NSInteger PADDING = 20;

// White space cropping functions with minor modifications, from Skim.app http://sourceforge.net/projects/skim-app/ — BSD license.

typedef struct _CCBitmapData {
  unsigned char *data;
  NSInteger bytesPerRow;
  NSInteger samplesPerPixel;
} CCBitmapData;

static inline BOOL 
differentPixels(const unsigned char *p1, 
                const unsigned char *p2, 
                NSUInteger count)
{
  NSUInteger i;    
  for (i = 0; i < count; i++) {
    if ((p2[i] > p1[i] && p2[i] - p1[i] > EPSILON) || (p1[i] > p2[i] && p1[i] - p2[i] > EPSILON))
      return YES;
  }
  
  return NO;
}

static inline void 
getPixel(CCBitmapData *bitmap, 
         NSInteger x,
         NSInteger y,
         unsigned char pixel[])
{
  NSInteger spp = bitmap->samplesPerPixel;
  unsigned char *ptr = &(bitmap->data[(bitmap->bytesPerRow * y) + (x * spp)]);
  while (spp--)
    *pixel++ = *ptr++;
}

static BOOL
isSignificantPixel(CCBitmapData *bitmap,
                   NSInteger x,
                   NSInteger y,
                   NSInteger minX,
                   NSInteger maxX,
                   NSInteger minY,
                   NSInteger maxY,
                   unsigned char backgroundPixel[])
{
  NSInteger i, j, count = 0;
  unsigned char pixel[bitmap->samplesPerPixel];
  
  getPixel(bitmap, x, y, pixel);
  if (differentPixels(pixel, backgroundPixel, bitmap->samplesPerPixel)) {
    for (i = minX; i <= maxX; i++) {
      for (j = minY; j <= maxY; j++) {
        getPixel(bitmap, i, j, pixel);
        if (differentPixels(pixel, backgroundPixel, bitmap->samplesPerPixel)) {
          count += (ABS(i - x) < 4 && ABS(j - y) < 4) ? 2 : 1;
          if (count > THRESHOLD)
            return YES;
        }
      }
    }
  }
  return NO;
}

static CGRect
trimmedRectWithImage(UIImage *img)
{
  CGImageRef image = [img CGImage];
  NSUInteger width = CGImageGetWidth(image);
  NSUInteger height = CGImageGetHeight(image);
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  NSUInteger bytesPerPixel = 4;
  unsigned char *bitmapData = malloc(height * width * bytesPerPixel);
  NSUInteger bytesPerRow = bytesPerPixel * width;
  NSUInteger bitsPerComponent = 8;
  CGContextRef context = CGBitmapContextCreate(bitmapData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
  CGColorSpaceRelease(colorSpace);
  CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
  
  NSInteger i, iMax = CGBitmapContextGetWidth(context) - MARGIN;
  NSInteger j, jMax = CGBitmapContextGetHeight(context) - MARGIN;
  NSInteger samplesPerPixel = 4;
    //NSInteger bytesPerRow = CGBitmapContextGetBytesPerRow(context);
    //NSInteger samplesPerPixel = CGBitmapContextGetBitsPerPixel(context);
  unsigned char pixel[samplesPerPixel];
  
  memset(pixel, 0, samplesPerPixel);
  
  NSInteger iLeft = iMax;
  NSInteger jTop = jMax;
  NSInteger iRight = MARGIN - 1;
  NSInteger jBottom = MARGIN - 1;
  
    //void *bitmapData = CGBitmapContextGetData(context);
  CCBitmapData bitmap;
  bitmap.data = bitmapData;
  bitmap.bytesPerRow = bytesPerRow;
  bitmap.samplesPerPixel = samplesPerPixel;
  
  unsigned char backgroundPixel[samplesPerPixel];
  getPixel(&bitmap, MIN(MARGIN, iMax), MIN(MARGIN, jMax), backgroundPixel);
  
    // basic idea borrowed from ImageMagick's statistics.c implementation
  
    // top margin
  for (j = MARGIN; j < jTop; j++) {
    for (i = MARGIN; i < iMax; i++) {            
      if (isSignificantPixel(&bitmap, i, j, MAX(MARGIN, i - 5), MIN(iMax - 1, i + 5), MAX(MARGIN, j - 1), MIN(jMax - 1, j + 5), backgroundPixel)) {
          // keep in mind that we're manipulating corner points, not height/width
        jTop = j; // final
        jBottom = j;
        iLeft = i;
        iRight = i;
        break;
      }
    }
  }
  
  if (jTop == jMax){
      // no foreground pixel detected
    CGContextRelease(context);
    free(bitmapData);
    
    return CGRectZero;
  }
    // bottom margin
  for (j = jMax - 1; j > jBottom; j--) {
    for (i = MARGIN; i < iMax; i++) {            
      if (isSignificantPixel(&bitmap, i, j, MAX(MARGIN, i - 5), MIN(iMax - 1, i + 5), MAX(MARGIN, j - 5), MIN(jMax - 1, j + 1), backgroundPixel)) {
        jBottom = j; // final
        if (iLeft > i)
          iLeft = i;
        if (iRight < i)
          iRight = i;
        break;
      }
    }
  }
  
    // left margin
  for (i = MARGIN; i < iLeft; i++) {
    for (j = jTop; j <= jBottom; j++) {            
      if (isSignificantPixel(&bitmap, i, j, MAX(MARGIN, i - 1), MIN(iMax - 1, i + 5), MAX(MARGIN, j - 5), MIN(jMax - 1, j + 5), backgroundPixel)) {
        iLeft = i; // final
        break;
      }
    }
  }
  
    // right margin
  for (i = iMax - 1; i > iRight; i--) {
    for (j = jTop; j <= jBottom; j++) {            
      if (isSignificantPixel(&bitmap, i, j, MAX(MARGIN, i - 5), MIN(iMax - 1, i + 1), MAX(MARGIN, j - 5), MIN(jMax - 1, j + 5), backgroundPixel)) {
        iRight = i; // final
        break;
      }
    }
  }
  
    // check top margin if necessary
  if (jTop == MARGIN) {
    for (j = 0; j < MARGIN; j++) {
      for (i = MARGIN; i < iMax; i++) {            
        if (isSignificantPixel(&bitmap, i, j, MAX(MARGIN, i - 5), MIN(iMax - 1, i + 5), MAX(0, j - 1), MIN(jMax - 1, j + 5), backgroundPixel)) {
          jTop = j; // final
          break;
        }
      }
    }
  }
  
    // check bottom margin if necessary
  if (jBottom == jMax - 1) {
    for (j = jMax + MARGIN - 1; j > jMax - 1; j--) {
      for (i = MARGIN; i < iMax; i++) {            
        if (isSignificantPixel(&bitmap, i, j, MAX(MARGIN, i - 5), MIN(iMax - 1, i + 5), MAX(MARGIN, j - 5), MIN(jMax + MARGIN - 1, j + 1), backgroundPixel)) {
          jBottom = j; // final
          break;
        }
      }
    }
  }
  
    // check left margin if necessary
  if (iLeft == MARGIN) {
    for (i = 0; i < MARGIN; i++) {
      for (j = jTop; j <= jBottom; j++) {            
        if (isSignificantPixel(&bitmap, i, j, MAX(0, i - 1), MIN(iMax - 1, i + 5), MAX(MARGIN, j - 5), MIN(jMax - 1, j + 5), backgroundPixel)) {
          iLeft = i; // final
          break;
        }
      }
    }
  }
  
    // check right margin if necessary
  if (iRight == iMax - 1) {
    for (i = iMax + MARGIN - 1; i > iMax - 1; i--) {
      for (j = jTop; j <= jBottom; j++) {            
        if (isSignificantPixel(&bitmap, i, j, MAX(MARGIN, i - 5), MIN(iMax + MARGIN - 1, i + 1), MAX(MARGIN, j - 5), MIN(jMax - 1, j + 5), backgroundPixel)) {
          iRight = i; // final
          break;
        }
      }
    }
  }
  
  CGContextRelease(context);
  free(bitmapData);
    // finally, convert the corners to a bounding rect
  return CGRectMake(iLeft, jMax + MARGIN - jBottom - 1, iRight + 1 - iLeft, jBottom + 1 - jTop);
}

@implementation XANPDFScrollView

@synthesize cropsWhitespace;
@synthesize doc, pageNumber;

// You must ensure theDoc is not NULL
- (void)setDoc:(CGPDFDocumentRef)theDoc
{
  CGPDFDocumentRef tmp = CGPDFDocumentRetain(theDoc);
  CGPDFDocumentRelease(doc);
  doc = tmp;
  
  self.pageNumber = 1;
}

- (void)setPageNumber:(size_t)number
{
  pageNumber = number;

  CGPDFPageRelease(page);
  page = CGPDFPageRetain(CGPDFDocumentGetPage(doc, pageNumber));
  
  pageRect = cropsWhitespace 
    ? [self croppedRect] 
    : CGPDFPageGetBoxRect(page, kCGPDFCropBox);
  imageView.image = cropsWhitespace 
    ? [self croppedPageImage]
    : [self pageImage];
  [self updateLayout];
}

- (void)setCropsWhitespace:(BOOL)crops
{
  cropsWhitespace = crops;
  [self updateLayout];
}

- (id)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]){
    self.bouncesZoom = YES;
    self.delegate = self;
    self.backgroundColor = [UIColor whiteColor];
    
    imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    imageView.contentMode = UIViewContentModeScaleToFill;
    [self addSubview:imageView];
    [imageView release];
    
    maxScale = 4.0;
    self.maximumZoomScale = maxScale;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tap.numberOfTapsRequired = 2;
    [self addGestureRecognizer:tap];
    [tap release];
  }
  
  return self;
}

- (void)dealloc
{
  CGPDFDocumentRelease(doc);
  CGPDFPageRelease(page);
  
  [super dealloc];
}

#pragma mark -

- (void)layoutSubviews
{
  [super layoutSubviews];
  if (!page || !tiledView) return;
  
  CGSize boundsSize = self.bounds.size;
  CGRect frameToCenter = tiledView.frame;
  
  if (frameToCenter.size.width < boundsSize.width)
    frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
  else
    frameToCenter.origin.x = 0;
  
  if (frameToCenter.size.height < boundsSize.height)
    frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
  else 
    frameToCenter.origin.y = 0;
  
  imageView.hidden = self.zoomBouncing;
  imageView.frame = frameToCenter;
  tiledView.frame = frameToCenter;
  tiledView.contentScaleFactor = 1.0;
}

#pragma mark -
#pragma mark methods
- (UIImage *)pageImage
{
  CGRect rect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
  UIGraphicsBeginImageContext(rect.size);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextScaleCTM(context, 1, -1);
  CGContextTranslateCTM(context, 0, -rect.size.height);
  CGContextTranslateCTM(context, -rect.origin.x, -rect.origin.y);
  CGContextDrawPDFPage(context, page);
  UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return img;
}

- (UIImage *)croppedPageImage
{
  // remember to call pageRect = [self croppedRect] before
  UIGraphicsBeginImageContext(pageRect.size);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextScaleCTM(context, 1, -1);
  CGContextTranslateCTM(context, 0, -pageRect.size.height);
  CGContextTranslateCTM(context, -pageRect.origin.x, -pageRect.origin.y);
  CGContextDrawPDFPage(context, page);
  UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return img;
}

- (CGRect)croppedRect
{
  CGRect rect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
  CGRect r = trimmedRectWithImage([self pageImage]);
  r.origin.x += rect.origin.x;
  r.origin.y += rect.origin.y;
  r.size.height += MARGIN;
  
  return r;
}

// Need to call while view controller willAnimateRotationToInterfaceOrientation:duration:
- (void)updateLayout
{
  if (!page || self.bounds.size.width == 0.0) return;
  
  [oldTiledView removeFromSuperview];
  oldTiledView = nil;
  
  CGSize pageSize = pageRect.size;
  CGSize finalSize = self.bounds.size;
  
  if (pageSize.width > pageSize.height){
    finalSize.height = pageSize.height * (finalSize.width/pageSize.width);
    if (finalSize.height > self.bounds.size.height){
      finalSize.width *= (self.bounds.size.height/finalSize.height);
      finalSize.height = self.bounds.size.height;
    }
  } else {
    finalSize.width = pageSize.width * (finalSize.height/pageSize.height);
    if (finalSize.width > self.bounds.size.width){
      finalSize.height *= (self.bounds.size.width/finalSize.width);
      finalSize.width = self.frame.size.width;
    }
  }
  
  initialScale = finalSize.width / pageSize.width;

  if (currentScale < initialScale){
    currentScale = initialScale;
    self.maximumZoomScale = maxScale / currentScale;
    self.minimumZoomScale = initialScale / currentScale;
  }
  
  CGRect rect = pageRect;
  rect.size.width *= currentScale;
  rect.size.height *= currentScale;
  imageView.frame = rect;
  self.contentSize = rect.size;
  
  [tiledView removeFromSuperview];
  tiledView = [[XANPDFTiledView alloc] initWithFrame:rect doc:doc pageNumber:pageNumber scale:currentScale offset:pageRect.origin];
  [self addSubview:tiledView];
  [tiledView release];
  
  [self setNeedsLayout];
}

#pragma mark UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
  return tiledView;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView 
                          withView:(UIView *)view
{
	[oldTiledView removeFromSuperview];
  
	oldTiledView = tiledView;
	[self addSubview:oldTiledView];  
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView 
                       withView:(UIView *)view 
                        atScale:(float)scale
{
  currentScale *= scale;

  if (currentScale > maxScale){
    currentScale = maxScale;
    return;
  } else if (currentScale < initialScale){
    currentScale = initialScale;
    return;
  }
  
  CGRect r = pageRect;
	r.size.width *= currentScale;
  r.size.height *= currentScale;
	
  tiledView = [[XANPDFTiledView alloc] initWithFrame:r doc:doc pageNumber:pageNumber scale:currentScale offset:pageRect.origin];
	
	[self addSubview:tiledView];
  [tiledView release];
  
  self.maximumZoomScale = maxScale / currentScale;
  self.minimumZoomScale = initialScale / currentScale;
}

#pragma mark -
#pragma mark UIGestureRecognizer action
- (void)handleTap:(UITapGestureRecognizer *)tap
{
  CGFloat scale = pageRect.size.width > self.contentSize.width
    ? pageRect.size.width / tiledView.frame.size.width
    : pageRect.size.width*initialScale / tiledView.frame.size.width;
  
  CGPoint center = [tap locationInView:self];
  CGRect zoomRect;
  zoomRect.size.height = self.bounds.size.height / scale;
  zoomRect.size.width = self.bounds.size.width  / scale;  
  zoomRect.origin.x = center.x - (zoomRect.size.width  / 2.0);
  zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0);
  
  [self zoomToRect:zoomRect animated:YES];
}

@end

