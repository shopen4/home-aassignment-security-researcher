
#import <Foundation/Foundation.h>
#import <mach/mach.h>

#define MS_IN_S 1000

typedef struct
{
	mach_msg_header_t header;
	char body_str[1024];
} message;

typedef struct
{
	message message;
	mach_msg_trailer_t trailer;
} ReceiveMessage;

@interface ClientMach:NSObject
@property(assign, nonatomic) mach_port_t port;
@property(assign, nonatomic) mach_port_t replyPort;

- (int)startClient;
- (int)sendMessage;
- (mach_msg_return_t)receive_msg:(char *)message;

@end






