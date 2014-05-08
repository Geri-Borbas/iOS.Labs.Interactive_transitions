//
//  EPPZLeftSwipeTransition.m
//  InteractiveTransition
//
//  Created by Carnation on 26/03/14.
//  Copyright (c) 2014 eppz! development, LLC. All rights reserved.
//

#import "EPPZLeftSwipeTransition.h"


@implementation EPPZLeftSwipeTransition



#pragma mark - Setup

-(void)setup
{
    self.duration = 2.0;
    self.damping = 0.68;
    self.initialSpringVelocity = 0.48;
}


#pragma mark - Layouts

-(void)layoutStart
{
    // Presenting view (as is).
    self.presenterView.transform = CGAffineTransformIdentity;
    
    // Modal view (left out).
    self.modalView.transform = CGAffineTransformMakeTranslation(-self.modalView.bounds.size.width, 0.0);
}

-(void)layoutEnd
{
    // Presenting view (as is).
    self.presenterView.transform = CGAffineTransformIdentity;
    
    // Modal view (in).
    self.modalView.transform = CGAffineTransformMakeTranslation(0.0, 0.0);
}

-(void)layoutInteractive:(CGFloat) percent
{   
    // Modal view (0.0 is left out, 1.0 is in).
    self.modalView.transform = CGAffineTransformMakeTranslation(-self.modalView.bounds.size.width * (1.0 - percent), 0.0);
}


#pragma mark - Gestures



@end
