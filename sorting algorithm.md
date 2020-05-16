```cpp
#include <iostream>
#include <vector>
#include <queue>
#include <algorithm>
#include <random>
#include <ctime>
#include <functional>
using namespace std;

ostream& operator<<(ostream& os, const vector<int>& v) {

	int N = v.size();
	for (int i = 0; i < N; ++i) {
		os << v[i] << " ";
	}
	os << "\n";

	return os;
}

const int MAX_SIZE = 20;
vector<int> arr(MAX_SIZE);
vector<int> tempArr(MAX_SIZE);

void bubbleSort(vector<int>& data)
{
	int N = data.size();
	for (int i = N - 1; i > 0; --i) {
		for (int j = 0; j < i; ++j) {
			if (data[j] > data[j + 1])
				swap(data[j], data[j + 1]);
		}
	}
}

void selectionSort(vector<int>& data)
{
	int N = data.size();
	for (int i = 0; i < N - 1; ++i) {
		int temp = i;
		for (int j = i + 1; j < N; ++j) {
			if (data[temp] > data[j])
				temp = j;
		}
		swap(data[i], data[temp]);
	}
}

void insertionSort(vector<int>& data)
{
	int N = data.size();
	for (int i = 1; i < N; ++i) {
		int temp = data[i];
		int j = i - 1;
		while (j >= 0 && temp < data[j]) {
			data[j + 1] = data[j];
			--j;
		}
		data[j + 1] = temp;
	}
}

void quickSort(vector<int>& data, int low, int high)
{
	if (low >= high) return;
 
	int pivot = data[low];
	int left = low + 1, right = high;

	while (left <= right) {
		while (left <= high && data[left] <= pivot)
			left++;
		while (right > low && data[right] >= pivot)
			right--;

		if (left <= right) 
			swap(data[left], data[right]);
	}
	swap(data[low], data[right]); // 엇갈리는 경우

	quickSort(data, low, right - 1);
	quickSort(data, right + 1, high);
}

void merge(vector<int>& data, int low, int mid, int high)
{
	int i = low, j = mid + 1, k = low;

	while (i <= mid && j <= high) {
		if (data[i] < data[j]) {
			tempArr[k] = arr[i];
			k++; i++;
		}
		else {
			tempArr[k] = arr[j];
			k++; j++;
		}
	}

	if (i <= mid) {
		while (i <= mid) {
			tempArr[k] = arr[i];
			k++; i++;
		}
	}
	if (j <= high) {
		while (j <= high) {
			tempArr[k] = arr[j];
			k++; j++;
		}
	}

	for (int i = low; i <= high; ++i) {
		data[i] = tempArr[i];
	}
}
void mergeSort(vector<int>& data, int low, int high)
{
	if (low >= high) return;

	int mid = (low + high) / 2;
	mergeSort(data, low, mid);
	mergeSort(data, mid + 1, high);
	merge(data, low, mid, high);
}

/*
	digit : 자릿수
	base : 진법
*/
void radixSort(vector<int>& data, int digit, int base)
{
	int N = data.size();
	queue<int> radixQueue[10];

	for (int d = 0; d < digit; ++d) {
		int div = pow(base, d);
		int mod = div * 10;
		
		for (int i = 0; i < data.size(); ++i) {
			int index = (data[i] % mod) / div;
			radixQueue[index].push(data[i]);
		}

		for (int i = 0, index = 0; i < 10; ++i) {
			while (!radixQueue[i].empty()) {
				data[index] = radixQueue[i].front(); 
				radixQueue[i].pop();
				index++;
			}
		}
	}
}
int main() {
	ios_base::sync_with_stdio(false); cin.tie(NULL); cout.tie(NULL);

	mt19937 engine((unsigned int)time(NULL));
	uniform_int_distribution<int> distribution(0, 200);
	auto generator = bind(distribution, engine);

	for (int i = 0; i < MAX_SIZE; ++i) {
		arr[i] = generator();
	}
	cout << arr;

	//bubbleSort(arr);
	//selectionSort(arr);
	//insertionSort(arr);
	//quickSort(arr, 0, arr.size() - 1);
	//mergeSort(arr, 0, arr.size() - 1);
	radixSort(arr, 3, 10);
	
	cout << arr;

	bool isSored = is_sorted(arr.begin(), arr.end());

	if (isSored) cout << "True" << endl;
	else cout << "False" << endl;

	return 0;
}
```
