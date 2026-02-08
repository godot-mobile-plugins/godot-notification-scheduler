//
// © 2024-present https://github.com/cengiz-pz
//

#import "channel_data.h"

#import "nsp_converter.h"


const String CHANNEL_ID_PROPERTY = "id";
const String CHANNEL_NAME_PROPERTY = "name";
const String CHANNEL_DESCRIPTION_PROPERTY = "description";
const String CHANNEL_IMPORTANCE_PROPERTY = "importance";


@implementation ChannelData

- (instancetype) initWithDictionary:(Dictionary) channelData {
	if ((self = [super init])) {
		self.channelId = [NSPConverter toNsString:(String) channelData[CHANNEL_ID_PROPERTY]];
		self.channelName = [NSPConverter toNsString:(String) channelData[CHANNEL_NAME_PROPERTY]];
		if (channelData.has(CHANNEL_DESCRIPTION_PROPERTY)) {
			self.channelDescription = [NSPConverter toNsString:(String) channelData[CHANNEL_DESCRIPTION_PROPERTY]];
		}
		if (channelData.has(CHANNEL_IMPORTANCE_PROPERTY)) {
			self.channelImportance = [NSPConverter toNsNumber:channelData[CHANNEL_IMPORTANCE_PROPERTY]].integerValue;
		}
	}
	return self;
}

@end
