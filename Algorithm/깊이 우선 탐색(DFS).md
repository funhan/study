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


## 사이클 존재 여부 확인

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

## 절단점 찾기 알고리즘

무방향 그래프에서의 절단점(cut vertex)란 이 점과 인접한 간선들을 모두 지웠을 때 해당 컴포넌트가 두 개 이상으로 나뉘어지는 정점을 말함. 이를 한 번의 깊이 우선 탐색으로 그래프의 모든 절단점을 찾아낼 수 있음.  


임의의 정점에서부터 깊이 우선 탐색을 수행해 DFS 스패닝 트리를 만듦. 이때 어떤 정점 u가 절단점인지를 알 수 있는 방법은 다음과 같음. 무방향 그래프의 스패닝 트리에는 교차 간선이 없으므로, u와 연결된 정점들은 모두 u의 선조 아니면 자손임. 이때 u의 자손들을 루트로 하는 서브트리들은 서로 연결되어 있지 않음. 그 이유는 이들을 연결하는 간선이 있으면 교차 간선일 텐데, 무방향 그래프에서는 교차 간선이 없기 때문.  
따라서 u가 지워졌을 때 그래프가 쪼개지지 않는 유일한 경우는 u의 선조와 자손들이 전부 역방향 간선으로 연결되어 있을 때 뿐임. 이것을 확인하는 방법은 깊이 우선 탐색을 수행할 때, 각 정점을 루트로 하는 서브트리에서 역방향 간선을 통해 갈 수 있는 정점의 최소 깊이를 반환하면 됨. 만약 u의 자손들이 모두 역방향 간선을 통해 u의 선조로 올라갈 수 있다면 u는 절단점이 아님. 만약 u가 스패닝 트리의 루트라서 선조가 없는 경우, u가 둘 이상의 자손을 가질 때만 절단점이 됨.

### 무방향 그래프에서의 절단점 찾는 알고리즘 코드

```cpp
// 그래프의 인접 리스트 표현
vector<vector<int>> adj;
// 각 정점의 발견순서, -1로 초기화
vector<int> discovered;
// 각 정점이 절단점인지 여부 저장. false로 초기화
vector<bool> isCutVertex;
int counter = 0;
// here를 루트로 하는 서브트리에 있는 절단점들을 찾는다.
// 반환 값은 해당 서브트리에서 역방향 간선으로 갈 수 있는 정점 중
// 가장 일찍 발견된 정점의 발견 시점. 처음 호출할 때는 isRoot = ture
int findCutVertex(int here, bool isRoot) {
	// 발견 순서 기록
	discovered[here] = counter++;
	int ret = discovered[here];
	// 루트인 경우 절단점 판정을 위해 자손 서브트리의 개수를 셈.
	int children = 0;
	for(int i=0;i<adj[here].size();++i) {
		int there = adj[here][i];
		if(discovered[there] == -1) {
			++children;
			// 이 서브트리에서 갈 수 있는 가장 높은 정점의 번호
			int subtree = findCutVertex(there, false);
			// 그 노드가 자기 자신 이하에 있다면 현재 위치는 절단점
			if(!isRoot && subtree >= discovered[here])
				isCutVertex[here] = true;
			ret = min(ret, subtree);
		}
		else
			ret = min(ret, discovered[there]);
	}
	// 루트인 경우 절단점 판정은 서브트리의 개수로 
	if(isRoot) isCutVertex[here] = (children >= 2);
	return ret;
}
```
### 예) 다리 찾기

절단점 찾는 문제와 비슷하지만 약간 다른 그래프에서 다리 찾는 문제가 있음. 어떤 간선을 삭제했을 때 이 간선을 포함하던 컴포넌트가 두 개의 컴포넌트로 쪼개질 경우 이 간선을 다리(bridge)라고 부름. 이는 절단점 찾는 알고리즘을 간단히 변형해서 풀 수 있음.  
다리는 항상 트리 간선임. 따라서 트리 간선들에 대해서만 이 간선이 다리인지 판정하면 됨. DFS 스패닝 트리 상에서 u가 v의 부모일 때, 트리 간선 (u,v)가 다리가 되기 위해서는 v를 루트로 하는 서브트리와 이 외의 점들을 연결하는 유일한 간선이 (u,v)여야 함. 따라서 (u,v)를 제외한 역방향 간선으로 u보다 높은 정점에 갈 수 없는 경우 (u,v)가 다리라고 판정할 수 있음. 따라서 역방향 간선 중 자신의 부모로 가는 간선을 무시한 뒤, v와 그 자손들에서 역방향 간선으로 닿을 수 있는 정점의 최소 발견 순서가 u 후라면 (u,v)가 다리라고 판단할 수 있음.


## 이중 결합 컴포넌트와 강결합 컴포넌트

무방향 그래프에서 절단점을 포함하지 않는 서브그래프를 이중 결합 컴포넌트(biconnected component). 이는 무방향 그래프에서만 정의됨.  

방향 그래프에서는 강결합 컴포넌트(strongly connected components, SCC)가 있음. 이는 방향 그래프 상에서 두 정점 u와 v에 대해 양 방향으로 가는 경로가 모두 있을 때 두 정점은 같은 SCC에 속해 있다고 말함.





