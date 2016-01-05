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

You can now bring up the server:
```
startup.bat
```

Your rails server will come listening on port 3000.  Just hit:<BR>
(Be aware that the server will show a harmless exception when it comes up.)

http://localhost:3000

notes for deployment to production:

...
set RAILS_ENV=production
...

...
set RAILS_SERVE_STATIC_FILES=true (if and only if you do not have apache or nginx serving static files)
...

...
rake assets:precompile
...
