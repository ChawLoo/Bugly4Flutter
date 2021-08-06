#import "BuglyPlugin.h"
#if __has_include(<bugly/bugly-Swift.h>)
#import <bugly/bugly-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "bugly-Swift.h"
#endif

@implementation BuglyPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftBuglyPlugin registerWithRegistrar:registrar];
}
@end
