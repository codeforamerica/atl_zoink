# Courtbot Reporter

Performs ETL on data from any and all Courtbot APIs, then produces insights and interactive web-based data visualizations.

Currently-supported Courtbots include:
  + [Courtbot - Atlanta](https://github.com/codeforamerica/courtbot)

## Usage

[View](https://courtbot-reporter.herokuapp.com/) the application in a browser and/or request JSON data from the API.

### API Endpoints

#### Top Violations

Returns summary statistics for the statutes which have been cited the most.

 + `/api/v0/top-violations.json`
 + `/api/v0/top-violations.json?limit=3`

```` json
[
  {"violation_id":"2","violation_guid":"ATL 40-6-20","violation_name":"FAIL TO OBEY TRAF CTRL DEVICE","violation_category":"TODO","citation_count":"8804"},
  {"violation_id":"20","violation_guid":"ATL 40-2-8","violation_name":"NO TAG/ NO DECAL","violation_category":"TODO","citation_count":"5654"},
  {"violation_id":"9","violation_guid":"ATL 40-8-76.1","violation_name":"SAFETY BELT VIOLATION","violation_category":"TODO","citation_count":"3777"}
]

````











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

Update source code on staging (from master or another branch).

```` sh
git push heroku-staging master
# OR ...
git push heroku-staging yourbranch:master
````

[Debug](http://data-creative.info/process-documentation/2015/07/25/how-to-deploy-a-rails-app-to-heroku.html#debugging) as necessary.

Visit the application live at https://courtbot-reporter-staging.herokuapp.com/.

#### Production

Update source code on production.

```` sh
git push heroku-production master
````

Visit the application live at https://courtbot-reporter.herokuapp.com/.

### Maintenance

Initiate a new PG Backup from the Heroku Postgres console and click "Download" when it's ready.

Restore production database on local machine.

```` sh
psql
DROP DATABASE IF EXISTS courtbot_reporter_snapshot;
CREATE DATABASE courtbot_reporter_snapshot;
\q

pg_restore --verbose --clean --no-acl --no-owner -h localhost -U courtbot_reporter -d courtbot_reporter_snapshot latest.dump
````
