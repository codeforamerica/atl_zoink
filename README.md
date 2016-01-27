# Courtbot Reporter

Performs ETL on data from any and all Courtbot APIs, then produces insights and interactive web-based data visualizations.

Currently-supported Courtbots include:
  + [Courtbot - Atlanta](https://github.com/codeforamerica/courtbot)

## Installation

Download source code and install package dependencies.

```` sh
git clone git@github.com:codeforamerica/courtbot-reporter.git
cd courtbot-reporter
bundle install
````

## Prerequisites

[Install](http://data-creative.info/process-documentation/2015/07/18/how-to-set-up-a-mac-development-environment.html#ruby) ruby and bundler and rails.

[Install](http://data-creative.info/process-documentation/2015/07/18/how-to-set-up-a-mac-development-environment.html#postgresql) postgresql.

Create user.

```` sh
psql
CREATE USER courtbot_reporter WITH ENCRYPTED PASSWORD 'c0urtb0t!';
ALTER USER courtbot_reporter CREATEDB;
ALTER USER courtbot_reporter WITH SUPERUSER;
\q
````

Create database.

```` sh
bundle exec rake db:create
````

Migrate database.

```` sh
bundle exec rake db:migrate
````

## Usage

Extract, transform, and load all .csv data into a database.

```` sh
bundle exec rake atlanta:etl
````

## Deployment

Update source code on production.

```` sh
git push heroku master
````

[Debug](http://data-creative.info/process-documentation/2015/07/25/how-to-deploy-a-rails-app-to-heroku.html#debugging) as necessary.

Visit the application live at https://courtbot-reporter.herokuapp.com/.
