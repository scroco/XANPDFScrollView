//
//  XANTiledView.m
//  XANPDFScrollView
//
//  Created by Chen Xian'an on 12/27/10.
//  Copyright 2010 lazyapps.com. All rights reserved.
//

#import "XANPDFTiledView.h"
#import <QuartzCore/QuartzCore.h>

@implementation XANPDFTiledView

+ (Class)layerClass {
	return [CATiledLayer class];
}

- (id)initWithFrame:(CGRect)frame 
               page:(CGPDFPageRef)thePage 
              scale:(CGFloat)theScale
             offset:(CGPoint)theOffset
{    
  if (self = [super initWithFrame:frame]){
    CATiledLayer *layer = (CATiledLayer *)self.layer;
    layer.levelsOfDetail = 4;
    layer.levelsOfDetailBias = 4;
    layer.tileSize = CGSizeMake(512.0, 512.0);
    page = CGPDFPageRetain(thePage);
    scale = theScale;
    offset = theOffset;
  }
  
  return self;
}


- (void)dealloc
{
  CGPDFPageRelease(page);

  [super dealloc];
}

-(void)drawRect:(CGRect)r
{
}

-(void)drawLayer:(CALayer *)layer
       inContext:(CGContextRef)context
{
	CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
  CGContextFillRect(context, self.bounds);
	
	CGContextSaveGState(context);
	CGContextTranslateCTM(context, -offset.x*scale, self.bounds.size.height+offset.y*scale);
	CGContextScaleCTM(context, 1.0, -1.0);
	CGContextScaleCTM(context, scale, scale);	
	CGContextDrawPDFPage(context, page);
	CGContextRestoreGState(context);
}


@end
