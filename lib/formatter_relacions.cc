#include<bits/stdc++.h>
using namespace std;

int main() {
	string line;
	while (getline(cin, line)) {
		int n = line.size();
		int p = -1;
		string id, m1 = "@", m2 = "@", pr;
		for (int i=0; i<n; i++) {
			if (line[i] == '=') {
				id = line.substr(0, i-1);
			}
			if (line[i] == '"') {
				if (p == -1) p = i+1;
				else {
					if (m1 == "@") m1 = line.substr(p, i - p);
					else if (m2 == "@") m2 = line.substr(p, i - p); 
					else pr = line.substr(p, i - p);

					p = -1;
				}
			}
		}
		if (m1 > m2) swap(m1, m2);
		cout << "recipes[\"" << m1 << "-" << m2 << "\"] = Recipe(this, \"" << id << "\", " << m1 << ", " << m2 << ", " << pr << ");" << endl;
	}
}