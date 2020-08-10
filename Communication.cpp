#include "Communication.h"
#include <iostream>
using namespace std;

Communication::Communication()
{
	slen = sizeof(si_other);

	// ip주소를 출력.
	string ipAddress = getIPAddress();
	cout << "이 컴퓨터의 IP 주소 : " << ipAddress << endl;

	if (WSAStartup(MAKEWORD(2, 2), &wsa) != 0)
	{
		printf("Winsock 초기화 실패. Error code : %d", WSAGetLastError());
		exit(EXIT_FAILURE);
	}

	// 소켓 생성.
	if ((pc_socket = socket(AF_INET, SOCK_STREAM, 0)) == INVALID_SOCKET) //tcp
	{
		printf("소켓 생성 실패 : %d", WSAGetLastError());
		exit(EXIT_FAILURE);
	}

	server.sin_family = AF_INET;
	server.sin_addr.s_addr = INADDR_ANY;
	server.sin_port = htons(PORT);

	// 소켓에 타임아웃 설정.
	timeval tv;
	tv.tv_sec = 500.0f;	// 0.5초의 타임아웃.
	tv.tv_usec = 0;

	// 5초가 지나도록 수신이 없으면 타임아웃.
	setsockopt(pc_socket, SOL_SOCKET, SO_RCVTIMEO, (char *)&tv, sizeof(struct timeval));	

	// Bind.
	if (bind(pc_socket, (struct sockaddr *)&server, sizeof(server)) == SOCKET_ERROR)
	{
		printf("Bind failed with error code : %d", WSAGetLastError());
		exit(EXIT_FAILURE);
	}

	///////////////////////     3. listen() 함수    ///////////////////////

	// listen_sock이라는 소켓과 결합된 포트 상태를 대기상태로 변경
	// SOMAXCONN 수만큼 소켓 생성 가능, SOMAXCONN = 0x7fffffff; 
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
		// ip address 파악
		strcpy(ipaddr, inet_ntoa(*(struct in_addr*)hostinfo->h_addr_list[0]));
	}

	WSACleanup();

	return ipaddr;
}

void Communication::ReceiveData()
{
	// 클라이언트와 데이터 통신
	addrlen = sizeof(clientaddr);
	// 접속한 클라이언트와 통신가능 하도록 새로운 client_sock이라는 소켓 생성
	client_sock = accept(pc_socket, (SOCKADDR*)&clientaddr, &addrlen);
	if (client_sock == INVALID_SOCKET)
	{
		printf("accept failed with error code : %d", WSAGetLastError());
		exit(EXIT_FAILURE);
	}
	// inet_ntoa(clientaddr.sin_addr) = 32비트 숫자로 IP주소를 입력받아 
	//문자열 형태로 리턴
	// ntohs(clientaddr.sin_port) = 네트워크(빅 엔디안)에서 호스트
	//(리틀 엔디안)로 short형의 포트번호 리턴
	// 접속이 정확히 되었는지 확인 하기 위함(UI가 없으므로)

	string ipAddr = inet_ntoa(clientaddr.sin_addr);
	u_int port = ntohs(clientaddr.sin_port);
	
	cout << "\n[TCP 서버] 클라이언트 접속 : IP주소 = " + ipAddr + ", 포트번호 = ";
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
