//
//  TableViewDirectoryCell.h
//  UITableViewNavigation-2
//
//  Created by EnzoF on 23.09.16.
//  Copyright © 2016 EnzoF. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TableViewDirectoryCell : UITableViewCell

@property (weak,nonatomic) IBOutlet UILabel *fileName;
@property (weak,nonatomic) IBOutlet UILabel *size;

@end
