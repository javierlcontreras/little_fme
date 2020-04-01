#include<bits/stdc++.h>
using namespace std;

int main() {
	string line;
	while (getline(cin, line)) {
		int n = line.size();
		int p = -1;
		string id, nom = "@", desc;
		for (int i=0; i<n; i++) {
			if (line[i] == '=') {
				id = line.substr(0, i-1);
			}
			if (line[i] == '"') {
				if (p == -1) p = i+1;
				else {
					if (nom == "@") nom = line.substr(p, i - p);
					else desc = line.substr(p, i - p); 
					p = -1;
				}
			}
		}
	
		// MyElement erik = MyElement("anna", "Erik Ferrando", "Novato");
    	// elements["ivet"] = ivet;
    
		cout << "MyElement " << id << " = MyElement(this, \"" << id << "\", \"" << nom << "\", \"" << desc << "\");" << endl;  
		cout << "elements[\"" << id << "\"] = " << id << ";" << endl;
	}
}

