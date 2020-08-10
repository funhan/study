#pragma once
#include <winsock2.h>
#include <string>
#pragma comment(lib, "ws2_32.lib")

const int PORT = 8888;

class Communication
{
private :
	SOCKET pc_socket;
	sockaddr_in server, si_other;
	int slen;
	WSADATA wsa;

	// 데이터 통신에 사용할 변수
	SOCKET client_sock;
	SOCKADDR_IN clientaddr;
	int addrlen;


public:
	Communication();
	~Communication();

	std::string getIPAddress();
	
	void ReceiveData();
	void SendData(int flag_intersection, int n_triangles, float* triangle_list);
	
};

