# 18F Projects Status Dashboard

[![Build Status](https://travis-ci.org/18F/github-dashing.png?branch=master)](https://travis-ci.org/18F/github-dashing)

Dashboard to monitor the health of 18F GitHub repos.

Widgets available at https://project-dashboard.18f.gov/default:

- [Travis CI](http://travis-ci.org) build status (updates every 2 minutes)
- Repos whose `.about.yml` defines them as testable but don't have builds
	running on a CI service such as Travis or CircleCI (updates once a day)
- Repos that don't have an `.about.yml` (updates once a day)

![Preview](assets/images/project_dashboard_default_preview.png?raw=true)

Widgets available at https://project-dashboard.18f.gov/github_stats:

- Trend projections for current month on issues opened, issues closed and pull requests

![Preview](assets/images/project_dashboard_github_stats_preview.png?raw=true)

The dashboard is based on [Dashing](http://shopify.github.com/dashing), a Ruby
web application built on the [Sinatra](http://www.sinatrarb.com) framework.

APIs used:

- [GitHub](https://developer.github.com/)
- [Travis](http://docs.travis-ci.com/api/)
- [18F Team API/Projects](https://team-api.18f.gov/public/api/projects/)

## Setup

    git clone https://github.com/18F/github-dashing.git && cd github-dashing
    script/bootstrap

The project is configured through environment variables, which you can
modify in the `.env` file.

All environment variables are optional, apart from `ORG`.

- `ORG`: GitHub organization. Example: `18F`
- `SINCE`: Date string, or relative time parsed through
 [http://guides.rubyonrails.org/active_support_core_extensions.html](ActiveSupport).
 Example: `1.month.ago.beginning_of_month`, `2012-01-01`
- `GITHUB_OAUTH_TOKEN`: Required in order to avoid being rate limited.


### GitHub API Access

The dashboard uses the public GitHub API, which doesn't require authentication.
Depending on how many repositories you're iterating through, hundreds of API
calls might be necessary, which can quickly exhaust the API limitations for
unauthenticated use.

In order to authenticate, create a new [API Access Token] on your github.com
account, and add it to the `.env` configuration:

	GITHUB_OAUTH_TOKEN=2b0ff00...................

The dashboard uses the official GitHub API client for Ruby ([Octokit](https://github.com/octokit/octokit.rb)),
and respects HTTP cache headers where appropriate to avoid making unnecessary
API calls, thanks to [faraday-http-cache].

Dashing also supports [custom API endpoints] required for GitHub Enterprise,
by setting the `OCTOKIT_API_ENDPOINT` environment variable.

[API Access Token]: https://github.com/settings/applications
[faraday-http-cache]: https://github.com/plataformatec/faraday-http-cache
[custom API endpoints]: http://octokit.github.io/octokit.rb/#Using_ENV_variables

## Usage

Start the dashboard server:

	dashing start

Now you can browse the dashboard at
[http://localhost:3030/default](http://localhost:3030/default).

## Tasks

Once the server is started, the Dashing jobs start querying for their data at
a time specified by the `first_in` option, and then with a frequency specified
by the `every` option. See any job in the `jobs` directory for an example.

Credits
-------

Portions of this repo are based on Ingo Schommer's work in
https://github.com/chillu/github-dashing.

### Public domain

Ingo Schommer's original work remains covered under an [MIT License](https://github.com/chillu/github-dashing/blob/master/LICENSE).

18F's work on this project is in the worldwide [public domain](LICENSE.md), as are contributions to our project. As stated in [CONTRIBUTING](CONTRIBUTING.md):

> This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the [CC0 1.0 Universal public domain dedication](https://creativecommons.org/publicdomain/zero/1.0/).
>
> All contributions to this project will be released under the CC0 dedication. By submitting a pull request, you are agreeing to comply with this waiver of copyright interest.
