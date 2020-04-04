# 너비 우선 탐색

너비 우선 탐색은 시작점에서 가까운 정점부터 순서대로 방문하는 탐색 알고리즘.
깊이 우선 탐색과는 달리 너비 우선 탐색은 발견과 방문이 같지 않음. 모든 정점은 다음과 같은 세 가지 상태를 가짐
- 아직 발견되지 않은 상태
- 발견되었지만 아직 방문되지 않은 상태(큐에는 저장되어 있음)
- 방문된 상태


## 너비 우선 탐색 코드 - 인접 리스트 O(|V|+|E|), 인접 행렬 O(|V|^2)

```cpp
// 그래프의 인접 리스트 표현
vector<vector<int>> adj;
// start에서 시작해 그래프를 너비 우선 탐색하고 각 정점의 방문 순서를 반환
vector<int> bf(int start) {
	// 각 정점의 방문 여부
	vector<bool> discovered(adj.size(), false);
	// 방문할 정점 목록을 유지하는 큐
	queue<int> q;
	// 정점의 방문 순서
	vector<int> order;
	discovered[start] = true;
	q.push(start);
	while(!q.empty()) {
		int here = q.front();
		q.pop();
		// here을 방문
		order.push_back(here);
		for(int i=0;i<adj[here].size();++i) {
			int there = adj[here][i];
			// 처음 보는 정점이면 방문 목록에 추가
			if(!discovered[there]) {
				q.push(there);
				discovered[there] = trure;
			}
		}
	}
	return order;
}

```

## 너비 우선 탐색의 활용

너비 우선 탐색은 대게 `그래프의 최단 경로` 문제를 풀 때 사용.

시작점으로부터 다른 모든 정점까지의 최단 경로를 너비 우선 탐색 스패닝 트리 위에서 찾을 수 있음.


## 최단 경로 계산하는 너비 우선 탐색
```cpp
// start에서 시작해 그래프를 너비 우선 탐색하고 시작점부터 각 정점까지의
// 최단 거리와 너비 우선 탐색 스패닝 트리를 계산한다.
// distance[i] = start부터 i까지 최단 거리
// parent[i] = 너비 우선 탐색 스패닝 트리에서 i의 부모의 번호. 루트인 경우 자신의 번호
void bfs(int start, vector<int>& distance, vector<int>& parent) {
	distance = vector<int>(adj.size(), -1);
	parent = vector<int>(adj.size(), -1);	queue<int> q;
	distance[start] = 0;
	parent[start] = start;
	q.push(start);
	while(!q.empty()) {
		int here = q.front();
		q.pop();
		for(int i = 0;i<adj[here].size();++i) {
			int there = adj[here][i];
			if(distance[there] == -1) {
				q.push(there);
				distance[there] = distance[here] + 1;
				parent[there] = here;
			}
		}
	}
}

// v로부터 시작점까지의 최단 경로를 계산
vector<int> shortestPath(int v, const vector<int>& parent) {
	vector<int> path(1, v);
	while(parent[v] != v) {
		v = parent[v];
		path.push_back(v);
	}
	reverse(path.begin(), path.end());
	return path;
}

```



## 양방향 탐색

두 정점 사이의 최단 경로를 찾을 때 사용할 수 있는 굉장히 간단하면서도 유용한 테크닉 중 하나로 양방향 탐색(bidirection search)가 있음. 시작 정점에서 시작하는 정방향 탐색과, 목표 정점에서 시작해 거꾸로 올라오는 역방향 탐색을 동시에 하면서, 이 둘이 가운데서 만나면 종료하는 것.

이를 구현하기 위해서는, 정방향과 역방향 탐색에서 방문할 정점들을 모두 같은 큐에 넣되, 최단 거리를 저장할 때 정방향은 양수로, 역방향은 음수로 저장함. 인접한 상태를 검사했는데 서로 부호가 다르다면 가운데서 만났음을 알 수 있음.

양방향 탐색은 너비 우선 탐색보다 훨씬 적은 정점만을 방문하고도 최단 경로를 찾을 수 있기 때문에 메모리 사용량이 훨씬 적음.

하지만 이는 항상 사용할 수 있는 건 아님. 정방향 간선을 찾아내기는 쉽지만 역방향 간선을 찾아내기는 어려운 문제라던가, 각 정점마다 역방향 간선이 아주 많아서 역방향 탐색의 분기수가 지나치게 큰 경우에는 사용하지 힘듦.


### 양방향 탐색의 예

```cpp
// 15 퍼즐 문제의 상태를 표현하는 클래스
class State;
// x의 부호를 반환
int sgn(int x) {if(!x) return 0; return x > 0 ? 1 : -1; }
// x의 절대값을 1 증가
int incr(int x) { if(x < 0) return x - 1; return x + 1; }
// start에서 finish까지 가는 최단 경로의 길이를 반환
int bidirectional(State start, State finish) {
	// 각 정점까지의 최단 경로의 길이를 저장
	map<State, int> c;
	queue<State> q;
	// 시작과 목표 상태가 같은 경우 예외 처리
	if(start == finish) return 0;

	q.push(start); c[start] = 1;
	q.push(finish); c[finish] = -1;
	
	while(!q.empty()) {
		State here = q.front();
		q.pop();
		// 인접한 상태 검사
		vector<State> adjacent = here.hetAdjacent();
		for(int i =0;i<adjacent.size();++i) {
			map<State, int>::iterator it = c.find(adjacent[i]);
			if(it == c.end()) {
				c[adjacent[i]] = incr(c[here]);
				q.push(adjacent[i]);
			}
			// 가운데서 만난 경우
			else if(sgn(it->second) != sgn(c[here])) {
				return abs(it->second) + abs(c[here]) - 1;
			}
		}
	}
	return -1;
}

```

## 점점 깊어지는 탐색

양방향 탐색에서도 방문하는 정점 수는 최단 거에 따라 지수적으로 증가하기 때문에 규모가 큰 탐색을 수행 할때 메모리의 한계가 있음. 따라서 규모가 큰 탐색 문제를 풀 때는, 깊이 우선 탐색을 기반으로 한 방법을 사용해야 함. 깊이 우선 탐색은 정점을 발견하는 즉시 방문하므로 메모리를 거의 사용하지 않기 때문. 

물론 이대로라면 최단 경로를 찾기 힘듦. 첫 번째로, 깊이 우선 탐색은 시작 정점에서 부터 가까운 정점 순서대로 방문하지 않기 때문에 목표 상태를 찾는다고 하더라도 지금까지 찾은 경로가 최단 경로인지 확신할 수 업슴. 두 번째로, 각 정점을 방문했는지 확인하지 않기 때문에 한 상태를 두번 방문할 수도 있고, 심지어는 사이클에 빠질 수도 있음.

위와 같은 문제를 해결하기 위해 고안된 것이 점점 깊어지는 탐색(Iteratively Deepening Search, IDS). 이는 임의의 깊이 제한 L을 정한 후 이 제한보다 짧은 경로가 존재하는지를 깊이 우선 탐색으로 확인함. 답을 찾으면 이를 반환하고, 찾지 못하면 L을 늘려서 다시 시도함. 

### 점점 깊어지는 탐색의 예

```cpp
class State;
int best;
void dfs(State here, const State& finish, int steps) {
	// 지금까지 구한 최적해보다 더 좋을 가능성이 없으면 버림.
	if(steps >= best) return;
	// 목표 상태에 도달
	if(here == finish) { best = steps; return; }
	vector<State> adjacent = here.getAdjacent();
	for(int i=0;i<adjacent.size();++i) {
		dfs(adjacent[i], finish, steps + 1);
	}
}

// 점점 깊어지는 탐색
int ids(State start, State finish, int growthStep) {
	for(int limit = 4; ;limit += growthStep) {
		best = limit + 1;
		dfs(start, finish, 0);
		if(best <= limit) return best;
	}
	return -1;
}
```


## 탐색 방법 선택

1. 상태 공간에서의 최단 경로를 찾는 경우, 너비 우선 탐색을 최우선적으로 고려. 너비 우선 탐새이 직관적이고 구현이 간단하기 때문임. 이때, 탐색의 깊이 한계가 정해져 있지 않거나 너무 깊어서 메모리 사용량이 너무 크지 않은지 확인.

2. 상태 공간에서의 최단 경로를 찾는데, 탐색의 최대 깊이가 정해져있고 네 우선 탐색을 하기에는 메모리와 시간이 부족할 경우 양방향 탐색을 고려. 이 경우 목표 상태에서 역방향으로 움직이기가 쉬워야 함.

3. 두 탐색이 모두 너무 메모리를 많이 사용하거나 너무 느린 경우, 최적화를 할 거리가 많은 점점 깊어지는 탐색을 사용.



# 상태 객체의 구현

상태를 표현하는 자료 구조의 선택은 프로그램 효율성에 큰 영향을 미침.

1. 상태에 대한 여러 연산을 가능한 한 효율적으로 구현.
2. 가능한 한 적은 메모리를 사용해야 함. 
	- 15-퍼즐 문제에서 게임판을 64비트 정수 하나로 비트마스크 표현.
	- 하노이의 탑에서 각 원반이 어느 기둥에 있는지 비트마스크로 나타냄. 기둥은 2비트로 표현 가능.















