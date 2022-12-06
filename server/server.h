

#import <Foundation/Foundation.h>
#import <mach/mach.h>

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

@interface ServerMach:NSObject

@property(assign, nonatomic) mach_port_t port;

- (int)startServer;

- (void)handleRequest;

- (mach_msg_return_t)receive_msg:(ReceiveMessage *)inMessage;

- (mach_msg_return_t)send_reply:(ReceiveMessage)receiveMessage;

@end






