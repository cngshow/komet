== README

You need to first get JRuby, here is the link to the 64 bit msi installer:

https://s3.amazonaws.com/jruby.org/downloads/9.1.8.0/jruby_windows_x64_9_1_8_0.exe

Get JRuby's complete jar file.  You can put it anywhere you want just remember where you put it!
I put it in the directory where JRuby is installed.

https://s3.amazonaws.com/jruby.org/downloads/9.1.8.0/jruby-complete-9.1.8.0.jar

You also need Maven: https://maven.apache.org/download.cgi
Place where you would like
Add the bin directory of the created directory [apache dir] to the PATH environment variable

Confirm with mvn -v in a new shell. 

You need to make sure you have the source code for the ISAAC-rest project on your system.

git clone https://cshupp@vadev.mantech.com:4848/git/r/ISAAC-rest.git

In rails root you will find a file called setup.bat.template.
Move this file to setup.bat, then you will need to modify the following environment variables:<br>
Download jdk if you don't already have it for line 5 http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html

GEM_HOME : (this is in line 2, make sure you create the directory you reference)

JAVA_HOME : (Line 4)

JRUBY_JAR: (This references JRuby's complete jar file.  Line 8)

ISAAC_PATH: (Line 6, the path to the folder where your Isaac Rest project is installed)



From a dos shell make sure you are in rails root (you can see the app directory right?), and run:
```
setup.bat
```

Now that your environment is setup you need to install bundler:
```
gem install bundler
```

Install your bundle!
```
bundle install
```

**RAILS_COMMON - git submodule**
We have moved the prop loader and logging code into a git repository at https://github.com/VA-CTT/rails_common.git so that the code can
be shared with rails_komet and the PRISME project


To pull the latest code do the following (replace my username with yours where appropriate.):
* VCS -> Update Project - from within RubyMine (https://www.jetbrains.com/help/ruby/2016.1/installing-and-launching.html)
* open .gitignore and comment out /lib/rails__common with a #
* open a terminal and navigate to rails_komet/lib
* git submodule add https://cshupp@vadev.mantech.com:4848/git/r/rails_common.git
* open .gitignore and uncomment /lib/rails__common
* run git reset from within the lib/rails_common directory
* run git  rm -f --cached rails_common from within the lib/rails_common directory if the line above fails


```
git reset .
```

You should now see an rails_common directory under the lib directory.

In RubyMine you may see a message concerning rails_common being under source control. If/when you do, click the add root button. This will allow you to make changes within the rails_komet project to the code in rails_common and commit those changes as well.


Open a terminal and navigate to rails root and run the command:
* mvn clean initialize  
* This will create the file:
* ./config/generated/yaml/IsaacMetadataAuxiliary.yaml
* Now run the following command to build the Isaac Rest project
* bundle exec rake isaac:build_isaac_rest



You can now bring up the server:
```
startup.bat
```

Your rails server will come listening on port 3000 or 3001.  Just hit:<BR>
(Be aware that the server will show a harmless exception when it comes up.)

http://localhost:3000

**Working with Isaac-Rest:**

Isaac-rest can be managed in your ruby mine IDE.  To build isaac rest, in your IDE run 'rake isaac:build_isaac_rest'
This will build isaac rest and generate the auxiliary metadata file.
To launch isaac-rest: 'rake isaac:launch_isaac_rest'.
To do it all: 'rake isaac:build_and_launch_isaac_rest'
Make sure you have configured your setup.bat (first) as outlined in setup.bat.template.  Make sure maven is on your path.

By the way, you need to have your git credentials stored locally so run...

```
git config --global credential.helper wincred
```


Developer addded config variables:

1: REST_CACHE_SIZE determines the maximum number of key,value pairs (Integer required  > 0) of ISAAC data this application will cache.
```
set REST_CACHE_SIZE = 1000
```