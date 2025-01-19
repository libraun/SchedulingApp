# Terrier Assessment - Jet Braun

* Ruby version: 3.4.1
* Rails version: 8.0.1

* System dependencies

This app is intended to be run on a Windows machine. This repository comes with a [Rakefile](/Rakefile) and a [Gemfile](/Gemfile)

To install all required RubyGems, run:
>$ bundle install


* Database creation & initialization

This app contains a contains a rake startup task that builds and initializes the database. This task runs automatically,
but can also be run using:

>$ rake start_app

Once the "start_app" task completes, the application can be run (on localhost, via port 3000)
using the following command:

>$ rails server 
