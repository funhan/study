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

## 예

1. 두 정점이 연결되어 있는지 확인
- 정점 u에 대해 dfs(u)를 하고, visited[]를 참조하면 u로부터 각 정점에 갈 수 있는지 확인 가능.

2. 연결된 부분집합의 개수
- dfsAll()에서 dfs()를 몇 번 호출하는 횟수를 세면 컴포넌트의 갯수를 셀 수 있음.

3. 위상 정렬
- 위상 정렬은 의존성이 있는 작업들이 주어질 때, 이들을 어떤 순서로 수행해야 하는지 계산. 각 작업을 정점으로 표현하고, 작업 간의 의존 관계를 간선으로 표현한 방향 그래프를 의존성 그래프(dependency graph)라고 함. 이 그래프는 사이클이 없는 그래프로, DAG임.

- 위상 정렬의 구현은 들어오는 간선이 하나도 없는 정점들을 하나씩 찾아서 정렬 뒤에 붙이고, 그래프에서 이 정점을 지우는 과정을 반복. 이는 dfs로 구현 가능. dfsAll()을 수행하며 dfs()가 종료할 때마다 현재 정점의 번호를 기록해놓고, dfsAll()이 종료한 뒤 기록된 순서를 뒤집으면 위상 정렬을 얻을 수 있음. 

# 깊이 우선 탐색과 간선의 분류

깊이 우선 탐색을 수행하면 그 과정에서 그래프의 모든 간선을 한 번씩은 만나게 됨. 그중 일부 간선은 처음 발견한 정점으로 연결되어 있어서 따라가고, 나머지는 무시됨. 이때, 깊이 우선 탐색으로 그래프의 따라가는 간선을 모아 보면 트리 형태를 가지게 됨. 이를 DFS 스패닝 트리(DFS Spanning Tree)라고 부름. 이를 생성하고 나면 그래프의 모든 간선을 네 가지로 분류할 수 있음.

- 트리 간선(tree edge) : 스패닝 트리에 포함된 간선
- 순방향 간선(forward edge) : 스패닝 트리의 선조에서 자손으로 연결되지만 트리 간선이 아닌 간선
- 역방향 간선(back edge) : 스패닝 트리의 자손에서 선조로 연결되지만 트리 간선이 아닌 간선
- 교차 간선(cross edge) : 트리에서 선조와 자손 관계가 아닌 정점들 간에 연결된 간선. 위 세 가지를 제외한 간선.  

*무방향 그래프에서는 양방향으로 통행이 가능하므로 교차 간선이 있을 수 없음. 또한 순방향 간선과 역방향 간선의 구분이 없음.*


### 사이클 존재 여부 확인

사이클의 존재 여부는 역방향 간선의 존재 여부와 동치임. 사이클에 포함된 정점 중 깊이 우선 탐색 과정에서 처음 만나는 정점을 u라고 하면, dfs(u)는 u에서 갈 수 있는 정점들을 모두 방문한 후에 종료됨. 따라서 깊이 우선 탐색은 사이클에서 u 이전에 있는 정점을 dfs(u)가 종료하기 전에 방문하게 되는데, 그러면 이 정점에서 u로 가는 정점은 항상 역방향 간선이 됨.

## 간선 구분 구현 코드
```cpp
// 그래프의 인접 리스트 표현
vector<vector<int>> adj;
// dicovered[i] = i번 정점의 발견 순서
// finished[i] = dfs(i)가 종료 여부
vector<int> discovered, finished;
// 지금까지 발견한 정점의 수
int counter;

void dfs(int here) {
	dicovered[here] = counter++;
	// 모든 인접 정점을 순회
	for(int i=0;i<adj[here].size();++i) {
		int there = adj[here][i];
		cout << "(" << here << "," << there << ") is a ";
		// 방문한 적이 없다면 방문
		if(discovered[there] == -1) {
			cout << "tree edge" << endl;
			dfs(there);
		}
		// 만약 there가 here보다 늦게 발견됐으면 there는 here의 후손
		else if(discovered[here] < discovered[there]) {
			cout << "forward edge" << endl;
		}
		// 만약 dfs(there)가 아직 종료하지 않았으면 there은 here의 선조
		else if(finished[there] == 0) {
			cout << "back edge" << endl;
		}
		// 이 외의 경우 교차 간선
		else {
			cout << "cross edge" << endl;
		}
	}
	finished[here] = 1;
}
```















