# include <iostream>
# include <fstream>
# include <string>
# include <unistd.h>

using namespace std;
int main(int argc, char* argv[]){
    long long curPos = 0, nxtPos;
    ifstream file;
    string timestamp, hostname, progname, filename, user, log, logcommand, mvcommand, purefilename;
    while(true){
    	file.open("/var/log/sftp.log", ios::in);
    	string s;
	file.seekg(0, file.end);
	nxtPos = file.tellg();
	file.seekg(0, file.beg);
	if(nxtPos > curPos){
	    file.seekg(curPos);
	    while(getline(file, s) && s.size() > 0){
		if(s.find("session opened") != string::npos){
		    user = s.substr(s.find("user") + 5, s.find("from") - s.find("user") - 6);
		}
	        if(s.find(".exe") != string::npos && s.find("open") != string::npos && s.find("WRITE,CREATE") != string::npos){
		    /*timestamp = s.substr(0, 15);
		    hostname = s.substr(16, 7);
		    int pid = getpid();
		    char spid[8];
		    sprintf(spid, "%d", pid);
		    progname = string(getprogname()) + "[" + spid + "]";*/
		    filename = "/home/sftp" + s.substr(52, s.find(".exe")+4-52);
		    log = /*timestamp + " " + hostname + " " + progname + ": " + */filename + " violate file detected. Uploaded by " + user + ".";
		    logcommand = "echo '" + log + "' | logger -p LOCAL3.warn";
		    mvcommand = "sudo mv " + filename + " /home/sftp/hidden/.exe";
		    cout << mvcommand << '\n';
		    system(logcommand.c_str());
		    system(mvcommand.c_str());
		    //cout << logcommand << '\n';
		    //cout << s << "\n";
		    //cout << log << "\n";
		    //cout << command << '\n';

		}
	    }
	    curPos = nxtPos;
	}
	//cout << "test\n";
	//usleep(1000000);
	file.close();
    }
}
