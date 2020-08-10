#include "Communication.h"
#include <iostream>
using namespace std;

Communication::Communication()
{
	slen = sizeof(si_other);

	// ip�ּҸ� ���.
	string ipAddress = getIPAddress();
	cout << "�� ��ǻ���� IP �ּ� : " << ipAddress << endl;

	if (WSAStartup(MAKEWORD(2, 2), &wsa) != 0)
	{
		printf("Winsock �ʱ�ȭ ����. Error code : %d", WSAGetLastError());
		exit(EXIT_FAILURE);
	}

	// ���� ����.
	if ((pc_socket = socket(AF_INET, SOCK_STREAM, 0)) == INVALID_SOCKET) //tcp
	{
		printf("���� ���� ���� : %d", WSAGetLastError());
		exit(EXIT_FAILURE);
	}

	server.sin_family = AF_INET;
	server.sin_addr.s_addr = INADDR_ANY;
	server.sin_port = htons(PORT);

	// ���Ͽ� Ÿ�Ӿƿ� ����.
	timeval tv;
	tv.tv_sec = 500.0f;	// 0.5���� Ÿ�Ӿƿ�.
	tv.tv_usec = 0;

	// 5�ʰ� �������� ������ ������ Ÿ�Ӿƿ�.
	setsockopt(pc_socket, SOL_SOCKET, SO_RCVTIMEO, (char *)&tv, sizeof(struct timeval));	

	// Bind.
	if (bind(pc_socket, (struct sockaddr *)&server, sizeof(server)) == SOCKET_ERROR)
	{
		printf("Bind failed with error code : %d", WSAGetLastError());
		exit(EXIT_FAILURE);
	}

	///////////////////////     3. listen() �Լ�    ///////////////////////

	// listen_sock�̶�� ���ϰ� ���յ� ��Ʈ ���¸� �����·� ����
	// SOMAXCONN ����ŭ ���� ���� ����, SOMAXCONN = 0x7fffffff; 
	if (listen(pc_socket, SOMAXCONN) == SOCKET_ERROR)
	{
		printf("listen failed with error code : %d", WSAGetLastError());
		exit(EXIT_FAILURE);
	}
}


Communication::~Communication()
{
	closesocket(pc_socket);
	WSACleanup();
}

std::string Communication::getIPAddress()
{
	WSADATA wsaData;
	WSAStartup(MAKEWORD(2, 2), &wsaData);

	PHOSTENT hostinfo;
	char hostname[50];
	char ipaddr[50];
	memset(hostname, 0, sizeof(hostname));
	memset(ipaddr, 0, sizeof(ipaddr));

	int nError = gethostname(hostname, sizeof(hostname));
	if (nError == 0)
	{
		hostinfo = gethostbyname(hostname);
		// ip address �ľ�
		strcpy(ipaddr, inet_ntoa(*(struct in_addr*)hostinfo->h_addr_list[0]));
	}

	WSACleanup();

	return ipaddr;
}

void Communication::ReceiveData()
{
	// Ŭ���̾�Ʈ�� ������ ���
	addrlen = sizeof(clientaddr);
	// ������ Ŭ���̾�Ʈ�� ��Ű��� �ϵ��� ���ο� client_sock�̶�� ���� ����
	client_sock = accept(pc_socket, (SOCKADDR*)&clientaddr, &addrlen);
	if (client_sock == INVALID_SOCKET)
	{
		printf("accept failed with error code : %d", WSAGetLastError());
		exit(EXIT_FAILURE);
	}
	// inet_ntoa(clientaddr.sin_addr) = 32��Ʈ ���ڷ� IP�ּҸ� �Է¹޾� 
	//���ڿ� ���·� ����
	// ntohs(clientaddr.sin_port) = ��Ʈ��ũ(�� �����)���� ȣ��Ʈ
	//(��Ʋ �����)�� short���� ��Ʈ��ȣ ����
	// ������ ��Ȯ�� �Ǿ����� Ȯ�� �ϱ� ����(UI�� �����Ƿ�)

	string ipAddr = inet_ntoa(clientaddr.sin_addr);
	u_int port = ntohs(clientaddr.sin_port);
	
	cout << "\n[TCP ����] Ŭ���̾�Ʈ ���� : IP�ּ� = " + ipAddr + ", ��Ʈ��ȣ = ";
	cout << port;
	cout << "\n";

	///////////////////////////// recv() //// 
	const int BUFSIZE = 64;

	char buf[BUFSIZE + 1];

	int retval = recv(client_sock, buf, sizeof(char), 0);
	while (retval = recv(client_sock, buf, sizeof(char), 0) == -1);

	if (retval == SOCKET_ERROR)
	{
		printf("recv failed with error code : %d", WSAGetLastError());
		exit(EXIT_FAILURE);
	}
	else if (retval == 0)
	{
		cout << "recv 0 : retval == 0\n";
		//break;
	}

	string text;
	text += buf[0];
	text += buf[1];
	text += buf[2];
	cout << "recv data : " + text << "\n";
}

void Communication::SendData(int flag_intersection, int n_triangles, float * triangle_list)
{
}
