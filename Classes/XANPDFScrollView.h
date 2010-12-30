//
//  XANPDFScrollView.h
//  XANPDFScrollView
//
//  Created by Chen Xian'an on 12/27/10.
//  Copyright 2010 lazyapps.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XANPDFTiledView;
@interface XANPDFScrollView : UIScrollView <UIScrollViewDelegate> {
  CGPDFDocumentRef PDFDoc;
  size_t pageNumber;
  CGPDFPageRef PDFPage;
  UIImageView *imageView;
  XANPDFTiledView *tiledView;
  XANPDFTiledView *oldTiledView;
  BOOL cropsWhitespace;
  CGFloat initialScale;
  CGFloat maxScale;
  CGFloat currentScale;
  CGRect pageRect;
  BOOL hasBouncingBeforeEndZooming;
  BOOL needsUpdatePage;
}

@property (nonatomic) CGPDFDocumentRef PDFDoc;
@property (nonatomic) size_t pageNumber;
@property (nonatomic, getter=isCropsWhitespace) BOOL cropsWhitespace;

- (id)initWithFrame:(CGRect)frame;
- (UIImage *)pageImage;
- (UIImage *)croppedPageImage;
- (CGRect)croppedRect;
- (void)updateLayout;

@end
