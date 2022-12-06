


#import "client.h"

int main(int argc, const char **argv)
{
    ClientMach *client = [[ClientMach alloc] init];
    int kr = [client startClient];
}
