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

	// ������ ��ſ� ����� ����
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

