//
//  OfferTableViewCell.h
//  IndixProductScanner
//
//  Created by Nalin Chhajer on 15/02/16.
//  Copyright © 2016 Indix. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OfferTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *productImage;

@property (weak, nonatomic) IBOutlet UILabel *storeNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;

@end
