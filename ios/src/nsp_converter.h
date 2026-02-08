//
// © 2024-present https://github.com/cengiz-pz
//

#ifndef nsp_converter_h
#define nsp_converter_h

#import <Foundation/Foundation.h>
#include "core/string/ustring.h"
#include "core/object/class_db.h"


@interface NSPConverter : NSObject

// From Godot
+ (NSString*) toNsString:(const String) godotString;
+ (NSNumber*) toNsNumber:(const Variant) v;
+ (NSDictionary*) toNsDictionary:(const Dictionary&) godotDictionary;


// To Godot
+ (String) toGodotString:(const NSString*) nsString;
+ (Dictionary) toGodotDictionary:(NSDictionary*) nsDictionary;
+ (Dictionary) nsUrlToGodotDictionary:(NSURL*) status;

@end

#endif /* nsp_converter_h */
