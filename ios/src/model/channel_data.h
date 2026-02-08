//
// © 2024-present https://github.com/cengiz-pz
//

#ifndef channel_data_h
#define channel_data_h

#import <Foundation/Foundation.h>

#include "core/object/class_db.h"


extern const String CHANNEL_ID_PROPERTY;
extern const String CHANNEL_NAME_PROPERTY;
extern const String CHANNEL_DESCRIPTION_PROPERTY;
extern const String CHANNEL_IMPORTANCE_PROPERTY;


@interface ChannelData : NSObject

@property (nonatomic, strong) NSString* channelId;
@property (nonatomic, strong) NSString* channelName;
@property (nonatomic, strong) NSString* channelDescription;
@property (nonatomic, assign) NSInteger channelImportance;

- (instancetype) initWithDictionary:(Dictionary) configData;

@end

#endif /* channel_data_h */
