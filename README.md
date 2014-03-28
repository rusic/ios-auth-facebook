# Hello ~~Facebook~~ Rusic Sample

### About

This is a very primitive example of how to integrate Rusic with Facebook in a native application. It is a modified version of the Hello Facebook Sample that is bundled with the Facebook SDK.

The app does a few basic actions

1. Allows you to authenticate with Facebook with the Facebook SDK.
2. Allows you to upload an image to Rusic
3. Allows you to create an `idea` on Rusic containing a title, content and single image.


### Usage

1. Install the Facebook SDK for iOS.

2. Run `gem install cocoapods`

3. Run `pod install`

4. Launch the HelloFacebookSample project using Xcode from the <Facebook SDK>/samples/HelloFacebookSample directory.

	> Launch from the root directory NOT the `HelloFacebookSample.xcodeproj` file.
	
5. In `HFViewController.m` change the following variables to match your account and and space.

	    self.api_key = @"2a5e3e02c586ee2c21b4fb8346aece7d";
	    self.space_id = @"416";
	    self.static_title = @"Test Title";
	    self.static_content = @"Test Content";
	    self.static_image = @"Test.jpg";
	    
### More information

- [https://developers.facebook.com](https://developers.facebook.com)
- [http://simpleweb.github.io/rusic-api-spec](http://simpleweb.github.io/rusic-api-spec)

### Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Keep your feature branch focused and short lived
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request
