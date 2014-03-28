/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "HFViewController.h"

#import <CoreLocation/CoreLocation.h>

#import "HFAppDelegate.h"

#import <UNIRest.h>

#import "ASIHTTPRequestConfig.h"
#import "ASIHTTPRequestDelegate.h"
#import "ASIProgressDelegate.h"
#import "ASICacheDelegate.h"
#import "ASIHTTPRequest.h"
//#import "ASIHTTPRequest.m"
#import "ASIDataCompressor.h"
//#import "ASIDataCompressor.m"
#import "ASIDataDecompressor.h"
//#import "ASIDataDecompressor.m"
#import "ASIFormDataRequest.h"
#import "ASIInputStream.h"
//#import "ASIInputStream.m"
//#import "ASIFormDataRequest.m"
#import "ASINetworkQueue.h"
//#import "ASINetworkQueue.m"
#import "ASIDownloadCache.h"
//#import "ASIDownloadCache.m"
#import "ASIAuthenticationDialog.h"
//#import "ASIAuthenticationDialog.m"
#import "Reachability.h"
//#import "Reachability.m"


@interface HFViewController () <FBLoginViewDelegate>

@property (strong, nonatomic) IBOutlet FBProfilePictureView *profilePic;
@property (strong, nonatomic) IBOutlet UIButton *buttonPostIdea;
@property (strong, nonatomic) IBOutlet UIButton *buttonpostImage;
@property (strong, nonatomic) IBOutlet UILabel *labelFirstName;
@property (strong, nonatomic) id<FBGraphUser> loggedInUser;

@property (strong, nonatomic) NSString *rusic_participant_token;
@property (strong, nonatomic) NSString *image_id;

@property (strong, nonatomic) NSString *api_key;
@property (strong, nonatomic) NSString *space_id;
@property (strong, nonatomic) NSString *static_title;
@property (strong, nonatomic) NSString *static_content;
@property (strong, nonatomic) NSString *static_image;

- (IBAction)postIdeaClick:(UIButton *)sender;
- (IBAction)postImageClick:(UIButton *)sender;

- (void)showAlert:(NSString *)message
           result:(id)result
            error:(NSError *)error;


@end

@implementation HFViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    
    self.api_key = @"2a5e3e02c586ee2c21b4fb8346aece7d";
    self.space_id = @"416";
    self.static_title = @"Test Title";
    self.static_content = @"Test Content";
    self.static_image = @"Test.jpg";
    
    [super viewDidLoad];

    // Create Login View so that the app will be granted "status_update" permission.
    FBLoginView *loginview = [[FBLoginView alloc] init];

    loginview.frame = CGRectOffset(loginview.frame, 5, 5);
#ifdef __IPHONE_7_0
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_7_0
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        loginview.frame = CGRectOffset(loginview.frame, 5, 25);
    }
#endif
#endif
#endif
    loginview.delegate = self;

    [self.view addSubview:loginview];

    [loginview sizeToFit];
}

- (void)viewDidUnload {
    self.buttonPostIdea = nil;
    self.buttonpostImage = nil;
    self.labelFirstName = nil;
    self.loggedInUser = nil;
    self.profilePic = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark - FBLoginViewDelegate

- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
    // first get the buttons set for login mode
    self.buttonPostIdea.enabled = NO;
    self.buttonpostImage.enabled = YES;

}

- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView
                            user:(id<FBGraphUser>)user {
    // here we use helper properties of FBGraphUser to dot-through to first_name and
    // id properties of the json response from the server; alternatively we could use
    // NSDictionary methods such as objectForKey to get values from the my json object
    self.labelFirstName.text = [NSString stringWithFormat:@"Hello %@!", user.first_name];
    // setting the profileID property of the FBProfilePictureView instance
    // causes the control to fetch and display the profile picture for the user
    self.profilePic.profileID = user.id;
    self.loggedInUser = user;

    // Set up the headers including the X-API-Key provided by Rusic admin system
    NSDictionary* headers = @{
        @"accept": @"application/vnd.rusic.v1+json",
        @"X-API-Key": self.api_key
    };

    // Setup parameters for creating a new participant
    NSDictionary* parameters = @{
        @"participant[provider]": @"facebook",
        @"participant[uid]": user.id,
        @"participant[oauth_token]": [[[FBSession activeSession] accessTokenData] accessToken],
        @"participant[nickname]": user.username
    };

    // Post to the participant endpoint with the headers and parametes defined aboce
    [[UNIRest post:^(UNISimpleRequest* request) {
        [request setUrl:@"http://api.rusic.com/participants"];
        [request setHeaders:headers];
        [request setParameters:parameters];
    }] asJsonAsync:^(UNIHTTPJsonResponse* response, NSError *error) {
        // Get the response body
        UNIJsonNode* body = [response body];

        // Create a dictionary of the response body
        NSDictionary* dic = [body JSONObject];

        // Set the participant token to the rusic_participant_token key
        self.rusic_participant_token = [dic objectForKey:@"rusic_participant_token"];

        // Log the token out
        NSLog(@"rusic_participant_token: %@", self.rusic_participant_token);
    }];


}

- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
    // test to see if we can use the share dialog built into the Facebook application
    FBShareDialogParams *p = [[FBShareDialogParams alloc] init];
    p.link = [NSURL URLWithString:@"http://developers.facebook.com/ios"];
#ifdef DEBUG
    [FBSettings enableBetaFeatures:FBBetaFeaturesShareDialog];
#endif

    self.buttonPostIdea.enabled = NO;
    self.buttonpostImage.enabled = NO;

    self.profilePic.profileID = nil;
    self.labelFirstName.text = nil;
    self.loggedInUser = nil;
}

- (void)loginView:(FBLoginView *)loginView handleError:(NSError *)error {
    // see https://developers.facebook.com/docs/reference/api/errors/ for general guidance on error handling for Facebook API
    // our policy here is to let the login view handle errors, but to log the results
    NSLog(@"FBLoginView encountered an error=%@", error);
}

#pragma mark -

// POST IDEA HANDLER
- (IBAction)postIdeaClick:(UIButton *)sender {

    NSLog(@"About to post idea to Rusic");

    // Setup Header providing the X-Rusic-Participant-Token
    NSDictionary* headers = @{
      @"accept": @"application/vnd.rusic.v1+json",
      @"X-API-Key": self.api_key,
      @"X-Rusic-Participant-Token": self.rusic_participant_token
    };

    // Get the image ID
    NSString *image = [NSString stringWithFormat:@"%@", self.image_id];

    // Setup Parameters with some static (fake) data
    NSDictionary* parameters = @{
      @"idea[title]": self.static_title,
      @"idea[content]": self.static_content,
      @"idea[image_ids][]": image
    };
    
    NSString *url = [NSString stringWithFormat:@"http://api.rusic.com/buckets/%@/ideas", self.space_id];

    NSLog(@"%@", url);
    
    // Make a post request to the Rusic `space` with the headers and parameter
    [[UNIRest post:^(UNISimpleRequest* request) {
        [request setUrl: url];
        [request setHeaders:headers];
        [request setParameters:parameters];
    }] asJsonAsync:^(UNIHTTPJsonResponse* response, NSError *error) {
        NSLog(@"Idea created!");
    }];

}

// POST IMAGE HANDLER
- (IBAction)postImageClick:(UIButton *)sender {

    NSLog(@"About to post image to Rusic");
    
    // Disable the button after the first tap
    self.buttonpostImage.enabled = NO;
    
    // Change the button to say uploading
    [self.buttonpostImage setTitle:@"Uploading Image..." forState:UIControlStateNormal];
    
    // Set the API URL
    NSString *apiurl = @"http://api.rusic.com/images";
    
    //  Set the image Name
    NSString *imagename = self.static_image;
    
    // Create a UIImage from the imagename
    UIImage *image = [UIImage imageNamed: imagename];

    // Log out the image size to prove it loaded correctly
    NSLog(@"Image width is %f", image.size.width);
    NSLog(@"Image height is %f", image.size.height);

    // Get the Image Data at full quality
	NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
    
    // Generate NSURL for the Image
    NSURL *url = [NSURL URLWithString: apiurl];
    
    // Create a ASIFormDataRequest
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    
    // Create a setDelegate to self to allow async events to bind
    [request setDelegate:self];
    
    // Set the request data
    [request setData:imageData withFileName:@"Default.png" andContentType:@"image/jpeg" forKey:@"image[file]"];
    
    // Set the request headers
    [request addRequestHeader:@"accept" value:@"application/vnd.rusic.v1+json"];
    [request addRequestHeader:@"X-API-Key" value: self.api_key];
    [request addRequestHeader:@"X-Rusic-Participant-Token" value: self.rusic_participant_token];

    // Start the request
    [request startAsynchronous];

}

- (void)requestFinished:(ASIFormDataRequest *)request
{

    NSLog(@"Image upload complete");

    // Get the raw response
    NSString *responseString = [request responseString];

    // Parse the json of the response
    NSData *jsonData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
    NSError* error;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:jsonData

                          options:kNilOptions
                          error:&error];

    // Set image_id to the `id`
    self.image_id = [json objectForKey:@"id"];
    
    // Change the post image button to say done
    [self.buttonpostImage setTitle:@"Done!" forState:UIControlStateNormal];
    
    // Enable the Post Idea button
    self.buttonPostIdea.enabled = YES;

}

- (void)requestFailed:(ASIFormDataRequest *)request
{
    NSLog(@"ERROR");
    NSError *error = [request error];
    NSLog(@"%@", error);
}

// UIAlertView helper for post buttons
- (void)showAlert:(NSString *)message
           result:(id)result
            error:(NSError *)error {

    NSString *alertMsg;
    NSString *alertTitle;
    if (error) {
        alertTitle = @"Error";
        // Since we use FBRequestConnectionErrorBehaviorAlertUser,
        // we do not need to surface our own alert view if there is an
        // an fberrorUserMessage unless the session is closed.
        if (error.fberrorUserMessage && FBSession.activeSession.isOpen) {
            alertTitle = nil;

        } else {
            // Otherwise, use a general "connection problem" message.
            alertMsg = @"Operation failed due to a connection problem, retry later.";
        }
    } else {
        NSDictionary *resultDict = (NSDictionary *)result;
        alertMsg = [NSString stringWithFormat:@"Successfully posted '%@'.", message];
        NSString *postId = [resultDict valueForKey:@"id"];
        if (!postId) {
            postId = [resultDict valueForKey:@"postId"];
        }
        if (postId) {
            alertMsg = [NSString stringWithFormat:@"%@\nPost ID: %@", alertMsg, postId];
        }
        alertTitle = @"Success";
    }

    if (alertTitle) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:alertTitle
                                                            message:alertMsg
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}



@end
