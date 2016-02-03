# Courtbot Reporter

Performs ETL on courtbot data, provides a JSON API, produces insights and interactive data visualizations.

Currently-supported Courtbots include:
  + [Courtbot - Atlanta](https://github.com/codeforamerica/courtbot)

## Usage

[View](https://courtbot-reporter.herokuapp.com/) the application in a browser and/or request JSON data from the API.

### API Endpoints

See [source code](/app/controllers/api/v0/) for full documentation.

#### Top Violations

Returns a list of violation codes which have been cited the most.

 + `/api/v0/top-violations.json`
 + `/api/v0/top-violations.json?limit=3`

```` json
[
  {"violation_id":"1", "violation_code":"40-6-20", "violation_description":"FAIL TO OBEY TRAF CTRL DEVICE", "citation_count":"3469"},
  {"violation_id":"9", "violation_code":"40-2-8", "violation_description":"NO TAG/ NO DECAL", "citation_count":"2515"},
  {"violation_id":"11", "violation_code":"40-8-76.1", "violation_description":"SAFETY BELT VIOLATION", "citation_count":"1960"}
]
````

#### Defendant Citation Distribution

Returns defendant counts per citation count.

 + `/api/v0/defendant-citation-distribution.json`
 + `/api/v0/defendant-citation-distribution.json?limit=20`

```` json
[
  {"citation_count":"1","defendant_count":"130706"},
  {"citation_count":"2","defendant_count":"29159"},
  {"citation_count":"3","defendant_count":"8987"},
  {"citation_count":"4","defendant_count":"3509"},
  {"citation_count":"5","defendant_count":"1409"},
  {"citation_count":"6","defendant_count":"678"},
  {"citation_count":"7","defendant_count":"314"},
  {"citation_count":"8","defendant_count":"170"},
  {"citation_count":"9","defendant_count":"86"},
  {"citation_count":"10","defendant_count":"61"},
  {"citation_count":"11","defendant_count":"31"},
  {"citation_count":"12","defendant_count":"19"},
  {"citation_count":"13","defendant_count":"14"},
  {"citation_count":"14","defendant_count":"5"},
  {"citation_count":"15","defendant_count":"6"},
  {"citation_count":"16","defendant_count":"2"},
  {"citation_count":"17","defendant_count":"2"},
  {"citation_count":"18","defendant_count":"4"},
  {"citation_count":"19","defendant_count":"4"},
  {"citation_count":"21","defendant_count":"1"}
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
