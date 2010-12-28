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
  CGPDFPageRef page;
  UIImageView *imageView;
  XANPDFTiledView *tiledView;
  XANPDFTiledView *oldTiledView;
  BOOL cropsWhitespace;
  CGFloat initialScale;
  CGFloat maxScale;
  CGFloat currentScale;
  CGRect pageRect;
}

@property (nonatomic) CGPDFPageRef page;
@property (nonatomic, getter=isCropsWhitespace) BOOL cropsWhitespace;

- (id)initWithFrame:(CGRect)frame;
- (UIImage *)pageImage;
- (UIImage *)croppedPageImage;
- (CGRect)croppedRect;
- (void)updateLayout;

@end
