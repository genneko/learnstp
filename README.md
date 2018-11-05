Small programs to help experiment Spanning Tree Protocol with FreeBSD if_bridge.  
For more details, look at the following post.

https://genneko.github.io/playing-with-bsd/networking/learning-stp

## Install
1. Install the required packages (I assume that sudo is already installed and configured). 
```
sudo pkg install git-lite p5-Mojolicious
```

2. Install the scripts and web application from GitHub.
```
mkdir ~/src
cd ~/src
git clone https://github.com/genneko/learnstp.git
cd learnstp
```

## Usage
### bridge.sh
bridge.sh is a shell script to help you configure and confirm bridge/STP topology on your FreeBSD system.
```
usage: # bridge.sh mesh [-R <root>] [<nbridegs> [<nlinks>]]
       # bridge.sh ring [-R <root>] [<nbridegs> [<nlinks>]]
       # bridge.sh inline [-R <root>] [<nbridegs> [<nlinks>]]
       # bridge.sh connect <bridge1> <bridge2>
       # bridge.sh disconnect <epair>...
       # bridge.sh linkup <epair>...
       # bridge.sh linkdown <epair>...
       # bridge.sh destroy <bridge>...
       # bridge.sh destroy-all
       $ bridge.sh show
```

* Create four bridges and connect them in full mesh.
```
sudo ./bridge.sh mesh 4
```

* Create four bridges and connect them in full mesh with the first bridge to be the root bridge.
```
sudo ./bridge.sh mesh -R 1 4
```

* Create four bridges and connect them in full mesh with two links between each bridge pair.
```
sudo ./bridge.sh mesh 4 2
```

* Create three bridges and connect them in a ring topology.
```
sudo ./bridge.sh ring 3
```
 
* Create three bridges and connect them in a line.
```
sudo ./bridge.sh inline 3
```

* Create a epair and Connect bridge3 and bridge4 with it.
```
sudo ./bridge.sh connect bridge3 bridge4
```

* Disconnect bridges connected with the specified epairs.
```
sudo ./bridge.sh disconnect epair6
```

* Bring down links (epairs).
```
sudo ./bridge.sh linkdown epair1
```

* Bring up links (epairs).
```
sudo ./bridge.sh linkup epair1
```

* Destroy bridges.
```
sudo ./bridge.sh destroy bridge4
```

* Destroy all bridges and epairs.
```
sudo ./bridge.sh destroy-all
```

* Show bridge information
```
./bridge.sh show
bridge0 32768.02:ff:00:00:07:0a desig root 32768.02:00:90:00:08:0b cost 2000
  epair0a  proto rstp  id 128.7   cost   2000:       root / forwarding
  epair1a  proto rstp  id 128.9   cost   2000:  alternate / discarding
  epair2a  proto rstp  id 128.11  cost   2000:  alternate / discarding

bridge1 32768.02:00:90:00:08:0b [root]
  epair0b  proto rstp  id 128.8   cost   2000: designated / forwarding
  epair3a  proto rstp  id 128.13  cost   2000: designated / forwarding
  epair4a  proto rstp  id 128.15  cost   2000: designated / forwarding

bridge2 32768.02:00:90:00:0a:0b desig root 32768.02:00:90:00:08:0b cost 2000
  epair1b  proto rstp  id 128.10  cost   2000: designated / forwarding
  epair3b  proto rstp  id 128.14  cost   2000:       root / forwarding
  epair5a  proto rstp  id 128.17  cost   2000: designated / forwarding

bridge3 32768.02:00:90:00:0c:0b desig root 32768.02:00:90:00:08:0b cost 2000
  epair2b  proto rstp  id 128.12  cost   2000: designated / forwarding
  epair4b  proto rstp  id 128.16  cost   2000:       root / forwarding
  epair5b  proto rstp  id 128.18  cost   2000:  alternate / discarding
```

### Visualization Web Application
1. Run the web application.
```
./run-app.sh
```

2. Access the web application from the host OS's web browser.
```
http://localhost:3000/index.html
```

3. Bridge topology is displayed in realtime.
![Visualizing STP bridges](https://genneko.github.io/images/learning-stp/rstp-4b-mesh-01.jpg)
