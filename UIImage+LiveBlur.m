#import "UIImage+LiveBlur.h"




UIKIT_EXTERN CGImageRef UIGetScreenImage();

@implementation UIImage (LiveBlur)
+(UIImage*)liveBlurForScreenWithQuality:(float)quality interpolation:(int)iQuality blurRadius:(float)radius{

CGRect mainScreen = [[UIScreen mainScreen] bounds];
float screenHeight = mainScreen.size.height;
float screenWidth = mainScreen.size.width;
CGImageRef screen = UIGetScreenImage();
UIImage *smallImage = [[[UIImage imageWithCGImage:screen] resizedImage:CGSizeMake(screenWidth / quality, screenHeight / quality) interpolationQuality:iQuality] stackBlur:radius];
UIImage *backgroundImage = [smallImage resizedImage:CGSizeMake(screenWidth,screenHeight) interpolationQuality:iQuality];// tintedImageUsingColor:[UIColor colorWithWhite:0.6 alpha:0.5]];
//backgroundImage = [UIImage imageWithCGImage:screen];


CGImageRelease(screen);
return backgroundImage;
}

@end