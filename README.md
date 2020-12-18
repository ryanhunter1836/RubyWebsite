# Wipers To You Website

## Running on a local server

To get started, install the WSL

In powershell as admin:

```
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

Download the Ubuntu distribution from the Microsoft store:

```
https://www.microsoft.com/en-us/p/ubuntu/9nblggh4msv6?activetab=pivot:overviewtab
```

Launch the WSL and go through the configuration steps, then install the dependencies for Ruby on Rails:

Add the necessary repositories
```
$ curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
$ curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
$ echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
$ sudo add-apt-repository ppa:chris-lea/redis-server
$ sudo apt-get update
```

Install dependencies for compiling Ruby
```
$ sudo apt-get install git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev     software-properties-common libffi-dev dirmngr gnupg apt-transport-https ca-certificates redis-server redis-tools nodejs yarn
```

Install Ruby via RVM
```
$ gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
$ sudo apt install rvm
$ rvm install 2.6.3
```

Check installation succeeded:
```
$ ruby –v
```

Install and configure the PostgreSQL Database
```
$ sudo apt-get install postgresql postgresql-contrib libpq-dev
# When asked to create an account, enter "rubyuser" as the username and "CkeyCaldHALf" as the password
$ cd /etc/postgresql/{distribution}/main
# Replace pg_hba.conf with the pg_hba conf file located in the repository at configuration_files/pg_hba.conf
$ sudo service postgresql restart
```

To get started with the app, first clone the repo (in the WSL terminal) and `cd` into the directory:
```
$ git clone https://github.com/ryanhunter1836/RubyWebsite
$ cd RubyWebsite
```

Then install the needed packages (while skipping any Ruby gems needed only in production):
```
$ yarn add jquery@3.4.1 bootstrap@3.4.1
$ bundle install --without production
```

Next, migrate the database:
```
$ rails db:migrate
```

Seed the database and run app on a local server:
```
$ rails db:seed
```

Finally, run the server
```
$ rails s -u webrick
```

You can then register a new user or log in as the admin using the admin username and password.  The local version is integrated with the test version of Stripe and has access to the email server, so all account modifications will be reflected

## Connecting to the database through pgAdmin
Download pgAdmin from https://www.pgadmin.org/download/pgadmin-4-windows/  
Launch the application and right click on servers -> create -> server  
Name the server whatever you want, and under the connection parameters put the following
```
hostname: localhost
username: rubyuser
password: CkeyCaldHALf
```
Don't forget to check "save password"

NOTE: the database server may not be running after restarting your computer, so log into the WSL and run
```
sudo service postgresql start
```
