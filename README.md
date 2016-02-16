== README

You need to first get JRuby, here is the link to the 64 bit msi installer:

https://s3.amazonaws.com/jruby.org/downloads/9.0.4.0/jruby_windows_x64_9_0_4_0.exe

Get JRuby's complete jar file.  You can put it anywhere you want just remember where you put it!
I put it in the directory where JRuby is installed.

https://s3.amazonaws.com/jruby.org/downloads/9.0.4.0/jruby-complete-9.0.4.0.jar

In rails root you will find a file called setup.bat.template.
Move this file to setup.bat, then you will need to modify the following environment variables:

GEM_HOME : (this is in line 2, make sure you create the directory you reference)<br>
JAVA_HOME : (Line 4)<br>
JRUBY_JAR: (This references JRuby's complete jar file.  Line 8)<br>

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

<hr>
<h1>ETS_COMMON - git submodule</h1>
We have moved the prop loader and logging code into a git repository at https://github.com/VA-CTT/ets_common.git so that the code can be shared with ets_tooling and the PRISME project

To pull the latest code do the following:
1) VCS -> Update Project - from within RubyMine
2) open a terminal and navigate to ets_tooling/lib
3) git submodule add https://github.com/VA-CTT/ets_common
4) run git reset from within the lib/ets_common directory

```
git reset .
```

You should now see an ets_common directory under the lib directory.

In RubyMine you may see a message concerning ets_common being under source control. If/when you do, click the add root button. This will allow you to make changes within the ets_tooling project to the code in ets_common and commit those changes as well.



<br>
<hr>
You can now bring up the server:
```
startup.bat
```

Your rails server will come listening on port 3000.  Just hit:<BR>
(Be aware that the server will show a harmless exception when it comes up.)

http://localhost:3000

notes for deployment to production:

```
set RAILS_ENV=production
```

```
set RAILS_SERVE_STATIC_FILES=true (if and only if you do not have apache or nginx serving static files)
```

```
rake assets:precompile
```


How do you run this in a J2EE server like GlassFish?  Here are some GlassFish instructions!  These instructions have been tested on GlassFish version 4.1.1.  You can obtain it here:

https://glassfish.java.net/download.html

Follow the install instructions on the site (you pretty much unzip it).

Before bringing up GlassFish, ensure that <b>jruby-complete-9.0.4.0.jar</b> is placed into the domain you intend to deploy your application.  In my case, on my box, in the directory:
```
C:\work\ETS\glassfish\glassfish4\glassfish\domains\domain1\lib\ext
```

You will want to bring GlassFish up via:
```
glassfish4/bin/asadmin start-domain
```

GlassFish deploys war files, so we will end up converting our rails app into a war file using the warbler gem.  Before running warbler though you need to run the asset pipeline to properly set up the application's javascript, css, and images for the war file.  In addition to that, if you intend to have a context root other than '/' you need to tell the asset pipeline!  By default the  the context root will be 'ets_tooling', so you should do this (from rails root):

```
set RAILS_RELATIVE_URL_ROOT=/ets_tooling
```

Then run the asset pipeline:
```
rake assets:precompile
```

Note:  Warbler uses 'production' as the default rails environment if you haven't set the appropriate environment variable.  Thus, if you wish to build a war file that defaults to test or development before running warble do this:
```
set RAILS_ENV=test
```


Now you can run warbler to generate your war:

```
warble
```


You will have a war file named ets_tooling.war.  Deploy it to GlassFish!!

http://localhost:4848/common/index.jsf
