Small programs to help experiment Spanning Tree Protocol with FreeBSD if_bridge.  
For more details, look at the following post.

https://genneko.github.com/playing-with-bsd/networking/learning-stp

## Quick Start
1. Install the required packages.
```
$ sudo pkg install git-lite p5-Mojolicious
```

2. Install the scripts and web application from GitHub.
```
$ mkdir ~/src
$ cd ~/src
$ git clone https://github.com/genneko/learnstp.git
$ cd learnstp
```

3. Create a topology where four bridges are meshed together.
```
$ sudo ./bridge.sh mesh
```

4. Run the web application.
```
$ ./run-app.sh
```

5. Access the web application from the host OS's web browser.
```
http://localhost:3000/index.html
```

6. Bring down some link to see how the logical topology changes.
```
$ sudo ./bridge.sh linkdown epair1
```

7. Destroy all bridges and epairs. Use with caution.
```
$ sudo ./bridge.sh destroy-all
```
