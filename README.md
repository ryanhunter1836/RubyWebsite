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

```
sudo apt-get update
sudo apt install gnupg
gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
sudo apt install software-properties-common
sudo apt-add-repository -y ppa:rael-gc/rvm
sudo apt update
sudo apt install rvm
rvm install 2.5.1
```

Check installation succeeded:

```
ruby –v
```

To get started with the app, first clone the repo and `cd` into the directory:

```
$ git clone https://github.com/mhartl/sample_app_6th_ed.git
$ cd sample_app_6th_ed
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
$ rails server
```

You can then register a new user or log in as the sample administrative user with the email `example@example.com` and password `foobar`.