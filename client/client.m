
#import "client.h"
#import <mach/mach.h>
#import <servers/bootstrap.h>

@interface ClientMach ()
@end

@implementation ClientMach

- (mach_msg_return_t)receive_msg:(char *)message {
    // Message buffer.
	ReceiveMessage receiveMessage = {0};

	mach_msg_return_t ret = mach_msg(
		/* msg */ (mach_msg_header_t *)&receiveMessage,
		/* option */ MACH_RCV_MSG | MACH_RCV_TIMEOUT,
		/* send size */ 0,
		/* recv size */ sizeof(receiveMessage),
		/* recv_name */ self.replyPort,
		/* timeout */ 1 * MS_IN_S,
		/* notify port */ MACH_PORT_NULL);

	if (ret != MACH_MSG_SUCCESS)
	{
		return ret;
	}

	NSLog(@"got response message!\n");
	NSLog(@"\t id: %d\n", receiveMessage.message.header.msgh_id);
	NSLog(@"\t bodys: %s\n", receiveMessage.message.body_str);

	if (strcmp(receiveMessage.message.body_str, message) == 0) {
		NSLog(@"\t The data is the same\n");
	} else {
		NSLog(@"\t The data is NOT the same\n");
	}

	return ret;
}


- (int)sendMessage {
// Create the message for sending
	message msg = {0};
	msg.header.msgh_remote_port = self.port;
	msg.header.msgh_local_port = self.replyPort;

	// MACH_MSG_TYPE_COPY_SEND: The message will carry a send right, and the caller should supply a send right.
	msg.header.msgh_bits = MACH_MSGH_BITS_SET(
		/* remote */ MACH_MSG_TYPE_COPY_SEND,
		/* local */ MACH_MSG_TYPE_MAKE_SEND_ONCE,
		/* voucher */ 0,
		/* other */ 0);
	msg.header.msgh_id = 4;
	msg.header.msgh_size = sizeof(msg);

	strcpy(msg.body_str, "test");

	// Mach messages are sent and received with the same API function, mach_msg()
	mach_msg_return_t ret = mach_msg(
		/* msg */ (mach_msg_header_t *)&msg,
		/* option */ MACH_SEND_MSG,
		/* send size */ sizeof(msg),
		/* recv size */ 0,
		/* recv_name */ MACH_PORT_NULL,
		/* timeout */ MACH_MSG_TIMEOUT_NONE,
		/* notify port */ MACH_PORT_NULL);

	while (ret == MACH_MSG_SUCCESS)
	{
		// ret = receive_msg(/* timeout */ 1 * MS_IN_S, msg.body_str);
        ret = [self receive_msg:(char *)msg.body_str];
	}

	if (ret == MACH_RCV_TIMED_OUT)
	{
		NSLog(@"Receive timed out, no more messages from server.\n");
	}
	else if (ret != MACH_MSG_SUCCESS)
	{
		NSLog(@"Failed to receive a message: %#x\n", ret);
		return 1;
	}

	return ret;
}

- (int)startClient
{
    int kr;
	mach_port_name_t task = mach_task_self();

	// Create bootstrap port
	mach_port_t bootstrap_port;
	kr = task_get_special_port(task, TASK_BOOTSTRAP_PORT, &bootstrap_port);

	if (kr != KERN_SUCCESS)
	{
		return EXIT_FAILURE;
	}

	NSLog(@"[*] Got special bootstrap port: 0x%x\n", bootstrap_port);

	// Get port to send to the com.nir.ipc.mach and store it in port
	// Any clients wishing to connect to a given service, can then look up the server port using a similar function: bootstrap_look_up
	// first argument: always bootstrap; second argument: name of service; third argument: out: server port
	mach_port_t port;
	kr = bootstrap_look_up(bootstrap_port, "com.nir.ipc.mach", &port);

	if (kr != KERN_SUCCESS)
	{
		return EXIT_FAILURE;
	}

    [self setPort:(mach_port_t)port];

	NSLog(@"[*] Port for com.nir.ipc.mach: 0x%x\n", port);


	mach_port_t replyPort;
	if (mach_port_allocate(task, MACH_PORT_RIGHT_RECEIVE, &replyPort) !=
		KERN_SUCCESS)
	{
		return EXIT_FAILURE;
	}

	if (mach_port_insert_right(
			task, replyPort, replyPort, MACH_MSG_TYPE_MAKE_SEND) !=
		KERN_SUCCESS)
	{
		return EXIT_FAILURE;
	}

    [self setReplyPort:(mach_port_t)replyPort];

    [self sendMessage];

    return KERN_SUCCESS;
}

@end
