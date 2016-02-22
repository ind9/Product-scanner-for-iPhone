//
//  ViewController.m
//  IndixProductScanner
//
//  Created by Nalin Chhajer on 11/02/16.
//  Copyright © 2016 Indix. All rights reserved.
//

#import "ViewController.h"
#import "OfferTableViewCell.h"

#define INDIX_API_ID
#define INDIX_API_KEY 


@interface ViewController ()
// Initialization
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *searchField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong) NSArray *offerArrayForUPC;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.activityIndicator.hidden = YES;
    
    [self performSearchForUPC:@"00753759975845"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Callback on search button clicked
- (IBAction)searchClicked:(id)sender {
    NSString * searchTermEnteredByUser = self.searchField.text;
    [self performSearchForUPC:searchTermEnteredByUser];
}

- (void)performSearchForUPC:(NSString *)upcString {
    // prepare indix url
    self.searchField.text = upcString;
    NSMutableString *searchUrlByIndix = [[NSMutableString alloc] initWithString:@"https://api.indix.com/v2/universal/products?countryCode=US"];
    [searchUrlByIndix appendString:[NSString stringWithFormat:@"&app_id=%@", INDIX_API_ID]];
    [searchUrlByIndix appendString:[NSString stringWithFormat:@"&app_key=%@", INDIX_API_KEY]];
    [searchUrlByIndix appendString:[NSString stringWithFormat:@"&upc=%@", upcString]];
    
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
    
    // Fetch products from indix url
    [self dojsonGetRequestForURL:[NSURL URLWithString:searchUrlByIndix] callOnSuccess:^(NSDictionary *jsonData) {
        [self onSuccessForUrlProductSearch:jsonData];
    } callOnFailure:^(NSError *error) {
        [self onFailureForUrlProductSearch:@"Error!!" message:@"There was an error, please check your net connection and try again"];
        self.activityIndicator.hidden = YES;
    }];
}



- (void)onSuccessForUrlProductSearch:(NSDictionary *)i_jsonData {
    id i_resultObject = i_jsonData[@"result"];
    NSNumber *i_countOfProducts = i_resultObject[@"count"];
    id i_allProductArray = i_resultObject[@"products"];
    
    if ([i_countOfProducts integerValue] == 0) {
        [self onFailureForUrlProductSearch:@"Error!!" message:@"No products found"];
        self.activityIndicator.hidden = YES;
    }
    else {
        NSArray *o_parsedarray = [self parseProductArrayToExtractProducts:i_allProductArray];
        self.offerArrayForUPC = o_parsedarray;
        [self.tableView reloadData];
        self.activityIndicator.hidden = YES;
    }

}

- (NSMutableArray *)parseProductArrayToExtractProducts:(NSArray *)i_allProductArray {
    NSMutableArray *o_parsedarray = [[NSMutableArray alloc] init];
    for (NSDictionary *productDictionary in i_allProductArray) {
        NSDictionary *allstoresDict = [productDictionary objectForKey:@"stores"];
        for(id key in allstoresDict) {
            NSDictionary *storeDictionary = [allstoresDict objectForKey:key];
            NSArray *productoffersArray = [storeDictionary objectForKey:@"offers"];
            for (NSDictionary *productOffers in productoffersArray) {
                NSMutableDictionary *parsedofferDict = [[NSMutableDictionary alloc] init];
                [parsedofferDict setObject:[productOffers objectForKey:@"imageUrl"] forKey:@"imageUrl"];
                [parsedofferDict setObject:[productOffers objectForKey:@"productUrl"] forKey:@"productUrl"];
                [parsedofferDict setObject:[productOffers objectForKey:@"seller"] forKey:@"seller"];
                [parsedofferDict setObject:[productOffers objectForKey:@"salePrice"] forKey:@"salePrice"];
                [parsedofferDict setObject:[productOffers objectForKey:@"listPrice"] forKey:@"listPrice"];
                [parsedofferDict setObject:[productDictionary objectForKey:@"currency"] forKey:@"currency"];
                [parsedofferDict setObject:[storeDictionary objectForKey:@"storeName"] forKey:@"storeName"];
                
                [o_parsedarray addObject:parsedofferDict];
            }
        }
    }
    return o_parsedarray;
}

- (void)onFailureForUrlProductSearch:(NSString *)title message:(NSString *)message {
    UIAlertController *alertcontroller = [[UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert] init];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alertcontroller addAction:okAction];
    [self presentViewController:alertcontroller animated:YES completion:^{
        
    }];
}

#pragma mark - Tableview delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.offerArrayForUPC count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self.offerArrayForUPC count] > 0) {
        return [NSString stringWithFormat:@"Total offers: %ld", [self.offerArrayForUPC count]];
    }
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    OfferTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"offerCell"];
    
    NSDictionary *offerDictionary = [self.offerArrayForUPC objectAtIndex:indexPath.row];
    cell.priceLabel.text = [self generatePriceStringForPrice:[offerDictionary objectForKey:@"salePrice"] type:[offerDictionary objectForKey:@"currency"]];
    
    NSMutableString *storeName = [[NSMutableString alloc] initWithString:[offerDictionary objectForKey:@"storeName"]];
    NSString *sellerName = [offerDictionary objectForKey:@"seller"];
    if (sellerName && sellerName.length > 0) {
        [storeName appendString:[NSString stringWithFormat:@" (%@)", sellerName]];
    }
    cell.storeNameLabel.text = storeName;
    
    
    if (offerDictionary[@"imageData"]) {
        cell.productImage.image = [UIImage imageWithData:offerDictionary[@"imageData"]];
    }
    else {
        cell.productImage.image = nil;
        
        NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:offerDictionary[@"imageUrl"]] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (data) {
                
                NSMutableDictionary *offerDict = [self offerWithImageUrl:response.URL];
                if (offerDict) {
                    offerDict[@"imageData"] = data;
                    UIImage *image = [UIImage imageWithData:data];
                    if (image) {
                        NSMutableDictionary *currentOffer = [self.offerArrayForUPC objectAtIndex:indexPath.row];
                        if ([offerDict[@"imageUrl"] isEqualToString:currentOffer[@"imageUrl"]]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                OfferTableViewCell *updateCell = (id)[tableView cellForRowAtIndexPath:indexPath];
                                if (updateCell) {
                                    updateCell.productImage.image = image;
                                }
                                
                            });
                        }
                    }
                }
                
            }
        }];
        [task resume];
    }
    
    
    
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString * producturlString = [[self.offerArrayForUPC objectAtIndex:indexPath.row] objectForKey:@"productUrl"];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:producturlString]];
}

- (NSMutableDictionary *)offerWithImageUrl:(NSURL *)url {
    for (NSMutableDictionary *object in self.offerArrayForUPC) {
        if ([[url absoluteString] isEqualToString:object[@"imageUrl"]]) {
            return object;
        }
    }
    return nil;
}

#pragma mark - Utilities
- (void)dojsonGetRequestForURL:(NSURL *)url callOnSuccess:(void(^)(NSDictionary *data))success callOnFailure:(void(^)(NSError *error))failure {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:url];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if ([(NSHTTPURLResponse*)response statusCode] == 200) {
            NSError *error;
            id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error) NSLog(@"%@", [error description]);
            dispatch_async(dispatch_get_main_queue(), ^{
                success(jsonObject);
            });
        }
        else {
            if (error) NSLog(@"%@", [error description]);
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }
    }] resume];
}

- (NSString *)generatePriceStringForPrice:(NSString *)price type:(NSString *)type {
    if ([[type lowercaseString] isEqualToString:@"usd"]) {
        return [NSString stringWithFormat:@"%@%0.2f", @"$", [price doubleValue]];
    }
    return price;
}

@end
