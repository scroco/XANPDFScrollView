//
//  XANTiledView.h
//  XANPDFScrollView
//
//  Created by Chen Xian'an on 12/27/10.
//  Copyright 2010 lazyapps.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XANPDFTiledView : UIView {
  CGPDFPageRef page;
  CGFloat scale;
  CGPoint offset;
}

- (id)initWithFrame:(CGRect)frame page:(CGPDFPageRef)page scale:(CGFloat)scale offset:(CGPoint)offset;

@end
