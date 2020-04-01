# 깊이 우선 탐색(DFS)

현재 정점과 인접한 간선들을 하나씩 검사하다가, 아직 방문하지 않은 정점으로 향하는 간선이 있다면 그 간선을 무조건 따라감. 이 과정에서 더이상 갈 곳이 없는 막힌 정점에 도달하면 포기하고, 마지막에 따라왔던 간선을 따라 뒤로 돌아감. 따라갈 간선이 없을 경우 이전으로 돌아가기때문에 재귀 호출(스택)로 쉽게 구현 가능.

## DFS 코드 - 인접리스트 O(|V|+|E|), 인접행렬 O(|V|^2)

모든 정점에 대해 순서대로 dfs()를 호출하는 dfsAll()이 존재함.
이는 그래프에서 모든 정점들이 간선을 통해 연결되어 있지 않을 수 있기 때문에, 그래프 전체 구조를 파악하기 위해서 필요함.

```cpp
// 그래프의 인접 리스트 표현
vector<vector<int>> adj;
// 각 정점을 방문했는지 여부를 나타냄.
vector<bool> visited;
// 깊이 우선 탐색 구현
void dfs(int here) {
	cout << "DFS visit " << here << endl;
	visited[here] = true;
	// 모든 인접 정점을 순회
	for(int i=0;i<adj[here].size();++i) {
		int there = adj[here][i];
		if(!visited[there])
			dfs(there);
	}
	// 더이상 방문할 정점이 없으니, 재귀 호출 종료. 
	// 이전 정점으로 돌아감
}
// 모든 정점을 방문.
void dfsAll() {
	// visited를 false로 초기화
	visited = vector<bool>(adj.size(), false);
	// 모든 정점을 순회하면서, 아직 방문한 적 없으면 방문.
	for(int i=0;i<adj.size();++i)
		if(!visited[i])
			dfs(i);
}
```

## 