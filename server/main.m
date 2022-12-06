


#import "server.h"



int main(int argc, const char **argv)
{
    ServerMach *server = [[ServerMach alloc] init];
    int kr = [server startServer];
    [server handleRequest];
    
    

    
}
