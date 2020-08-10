#include <iostream>
#include "Communication.h"
using namespace std;

int main() {
	Communication* communication = new Communication();
	while (1)
	{
		communication->ReceiveData();
	}

	delete communication;

	cout << "End Communication" << endl;
	return 0;
}