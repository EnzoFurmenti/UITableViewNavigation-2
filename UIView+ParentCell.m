//
//  UIView+ParentCell.m
//  UITableViewNavigation-2
//
//  Created by EnzoF on 24.09.16.
//  Copyright © 2016 EnzoF. All rights reserved.
//

#import "UIView+ParentCell.h"

@implementation UIView (ParentCell)

-(UITableViewCell*)superCell{
    if(!self.superview)
    {
        return nil;
    }
    if([self.superview isKindOfClass:[UITableViewCell class]])
    {
        return (UITableViewCell*)self.superview;
    }
    return [self.superview superCell];
}

@end
