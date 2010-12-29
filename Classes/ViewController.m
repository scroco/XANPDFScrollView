//
//  XANPDFScrollViewViewController.m
//  XANPDFScrollView
//
//  Created by Chen Xian'an on 12/27/10.
//  Copyright 2010 lazyapps.com. All rights reserved.
//

#import "ViewController.h"
#import "XANPDFScrollView.h"

@implementation ViewController



/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
  [super viewDidLoad];
  NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Africa" ofType:@"pdf"]];
  CGPDFDocumentRef doc = CGPDFDocumentCreateWithURL((CFURLRef)url);
  scrollView = [[XANPDFScrollView alloc] initWithFrame:self.view.bounds];
  scrollView.autoresizesSubviews = YES;
  scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  scrollView.doc = doc;
  CGPDFDocumentRelease(doc);
  [self.view addSubview:scrollView];
  [scrollView release];
  UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"crop"] style:UIBarButtonItemStyleBordered target:self action:@selector(crop:)];
  self.navigationItem.rightBarButtonItem = rightBarButton;
  [rightBarButton release];
  self.navigationItem.title = NSLocalizedString(@"XANPDFScrollView", nil);
}
                                                                            

- (void)crop:(UIBarButtonItem *)sender
{
  scrollView.cropsWhitespace = !scrollView.isCropsWhitespace;
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
  return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                         duration:(NSTimeInterval)duration
{
  [scrollView updateLayout];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

@end
