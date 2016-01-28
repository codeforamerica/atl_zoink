# Courtbot Reporter

Performs ETL on data from any and all Courtbot APIs, then produces insights and interactive web-based data visualizations.

Currently-supported Courtbots include:
  + [Courtbot - Atlanta](https://github.com/codeforamerica/courtbot)

## Contributing

### Installation

Download source code and install package dependencies.

```` sh
git clone git@github.com:codeforamerica/courtbot-reporter.git
cd courtbot-reporter
bundle install
````

### Prerequisites

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

### Usage

Detect all possible Courtbot API endpoints.

```` sh
bundle exec rake atlanta:detect
````

Extract .csv data from eligible Courtbot API endpoints.

```` sh
bundle exec rake atlanta:extract
````









### Testing

Create tests for new features.

Run all tests and make sure they pass before merging code into the master branch.

```` sh
bundle exec rspec spec/
````

### Deploying

NOTE: Staging and production servers use different databases but share the same database credentials.

#### Staging

Update source code on staging.

```` sh
git push heroku-staging master
````

[Debug](http://data-creative.info/process-documentation/2015/07/25/how-to-deploy-a-rails-app-to-heroku.html#debugging) as necessary.

Visit the application live at https://courtbot-reporter-staging.herokuapp.com/.

#### Production

Update source code on production.

```` sh
git push heroku-production master
````

Visit the application live at https://courtbot-reporter.herokuapp.com/.
