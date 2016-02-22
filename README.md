##Product scanner
This is an example project that demonstrate on how easy it is to use Indix API to scan a product and show all stores and prices across stores where product can be bought. Please feel free to download the project from Github https://github.com/nalinchhajer1/Product-scanner-for-iPhone for reference. Feel free to checkout screenshots.

###Get Started
1. Signup with Indix.com, and get your API ID and API key. 
2. Download this example  project and open `IndixProductScanner.xcodeproj` in your xcode.
3. Enter your API id and key in `ViewController.m`. Build and run.

###Product search from Indix API
It is relatively straight forward to find a product and details of all the stores where product is sold using Indix api, 

```
GET https://api.indix.com/v2/universal/products?countryCode=US&upc=00753759975845
```
which returns 

```
{
"message": "ok",
"result": {
"count": 1,
"products": [
	"title":"Garmin eTrex 10 GPS Unit",
	"currency":"USD",
	"stores": [
		"108":{
			...
			"storeName":"Cabelas",
			"offers":[
				{
					...
					"listPrice":109.99,
					"productUrl":"http://www.cabelas.com/product/Garmin-eTrex-GPS-Unit/1218229.uts?productVariantId=2963934"
				}]
			}
		]
	]
}

```


###Fetch offers in iOS app
To get started let's call a method `[self performSearchForUPC:@"00753759975845"];` in viewDidLoad which display all the offer for the given UPC.

```
- (void)performSearchForUPC:(NSString *)upcString {
    NSMutableString *searchUrlByIndix = [[NSMutableString alloc] initWithString:@"https://api.indix.com/v2/universal/products?countryCode=US"];
    [searchUrlByIndix appendString:[NSString stringWithFormat:@"&app_id=%@", INDIX_API_ID]];
    [searchUrlByIndix appendString:[NSString stringWithFormat:@"&app_key=%@", INDIX_API_KEY]];
    [searchUrlByIndix appendString:[NSString stringWithFormat:@"&upc=%@", upcString]];
    // Fetch products from indix url
    [self dojsonGetRequestForURL:[NSURL URLWithString:searchUrlByIndix] 
	    callOnSuccess:^(NSDictionary *jsonData) 
	    {
	        [self onSuccessForUrlProductSearch:jsonData];
	    } 
	    callOnFailure:^(NSError *error) 
	    {
	        [self onFailureForUrlProductSearch:@"Error!!" message:@"There was an error, please check your net connection and try again"];
	    }
    ];
}

```

`dojsonGetRequestForURL` is a function which perform a get request for the given URL and do a json parsing on top of the response. On success it executes method in `callOnSuccess` block and on failure it executes method in `callOnFailure` block

```
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
```
Once we are sure we got proper response, `onSuccessForUrlProductSearch:` will be executed.

```
- (void)onSuccessForUrlProductSearch:(NSDictionary *)i_jsonData {
    id i_resultObject = i_jsonData[@"result"];
    id i_allProductArray = i_resultObject[@"products"];
    NSNumber *i_countOfProducts = i_resultObject[@"count"];
    
    if ([i_countOfProducts integerValue] == 0) {
        [self onFailureForUrlProductSearch:@"Error!!" message:@"No products found"];
    }
    else {
        NSArray *o_parsedarray = [self parseProductArrayToExtractProducts:i_allProductArray];
        self.offerArrayForUPC = o_parsedarray;
        [self.tableView reloadData];
    }

}
```
First, check if we have products detail from the given upc, if yes we continue to parse it to fetch only those information we need

```
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

```

That is it, we successfully fetched and parsed the response, make sure we handle the error cases properly.

```
- (void)onFailureForUrlProductSearch:(NSString *)title message:(NSString *)message {
    UIAlertController *alertcontroller = [[UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert] init];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alertcontroller addAction:okAction];
    [self presentViewController:alertcontroller animated:YES completion:^{
        
    }];
}
```

