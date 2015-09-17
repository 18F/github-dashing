require 'json'
require 'time'
require 'dashing'
require 'active_support'
require 'active_support/core_ext'
require File.expand_path('../../lib/helper', __FILE__)

SCHEDULER.every '1d', first_in: '50s' do |_job|
  backend = GithubBackend.new
  opened_series = [[], []]
  closed_series = [[], []]
  pull_series = [[], []]
  month = ENV['SINCE'].to_datetime

  issues_by_period = backend.issue_count_by_status.group_by_month(month)

  issues_by_period.each_with_index do |(period, issues), i|
    timestamp = Time.strptime(period, '%Y-%m').to_i

    opened_count = issues.count { |issue| issue.key == 'open' && issue.type == 'issue' }
    opened_series[0] << {
      x: timestamp,
      y: opened_count
    }
    # Add empty second series stack, and extrapolate last month for better trend visualization
    opened_series_count =
      if i == issues_by_period.count - 1
        GithubDashing::Helper.extrapolate_to_month(opened_count) - opened_count
      else
        0
      end
    opened_series[1] << {
      x: timestamp,
      y: opened_series_count
    }

    closed_count = issues.count { |issue| issue.key == 'closed' && issue.type == 'issue' }
    closed_series[0] << {
      x: timestamp,
      y: closed_count
    }
    # Add empty second series stack, and extrapolate last month for better trend visualization
    closed_series_count =
      if i == issues_by_period.count - 1
        GithubDashing::Helper.extrapolate_to_month(closed_count) - closed_count
      else
        0
      end
    closed_series[1] << {
      x: timestamp,
      y: closed_series_count
    }

    # ----- PULL REQUESTS ------ #
    open_pulls_count = issues.count { |issue| issue.key == 'open' && issue.type == 'pull_request' }

    pull_series[0] << {
      x: timestamp,
      y: open_pulls_count
    }
    # Add empty second series stack, and extrapolate last month for better trend visualization
    pull_series_count =
      if i == issues_by_period.count - 1
        GithubDashing::Helper.extrapolate_to_month(open_pulls_count) - open_pulls_count
      else
        0
      end
    pull_series[1] << {
      x: timestamp,
      y: pull_series_count
    }
  end

  # rubocop:disable Style/RescueModifier
  opened = opened_series[0][-1][:y] rescue 0
  closed = closed_series[0][-1][:y] rescue 0
  opened_prev = opened_series[0][-2][:y] rescue 0
  closed_prev = closed_series[0][-2][:y] rescue 0
  # rubocop:enable Style/RescueModifier
  trend_opened = GithubDashing::Helper.trend_percentage_by_month(opened_prev, opened)
  trend_closed = GithubDashing::Helper.trend_percentage_by_month(closed_prev, closed)
  trend_class_opened = GithubDashing::Helper.trend_class(trend_opened)
  trend_class_closed = GithubDashing::Helper.trend_class(trend_closed)

  send_event('issues_stacked',
             series: [opened_series[0], closed_series[0]],
             displayedValue: opened,
             moreinfo: "<span title=\"#{trend_closed}\">#{closed}</span> closed (#{trend_closed})",
             difference: trend_opened,
             trend_class: trend_class_opened,
             arrow: 'icon-arrow-' + trend_class_opened
            )

  send_event('issues_opened',
             series: opened_series,
             displayedValue: opened,
             moreinfo: '',
             difference: trend_opened,
             trend_class: trend_class_opened,
             arrow: 'icon-arrow-' + trend_class_opened
            )

  send_event('issues_closed',
             series: closed_series,
             displayedValue: closed,
             moreinfo: '',
             difference: trend_closed,
             trend_class: trend_class_closed,
             arrow: 'icon-arrow-' + trend_class_closed
            )

  # ----------- PULL REQUEST STATS -------------------------- #

  # rubocop:disable Style/RescueModifier
  current = pull_series[0][-1][:y] rescue 0
  prev = pull_series[0][-2][:y] rescue 0
  # rubocop:enable Style/RescueModifier
  trend = GithubDashing::Helper.trend_percentage_by_month(prev, current)
  trend_class = GithubDashing::Helper.trend_class(trend)

  send_event(
    'pull_requests',
    series: pull_series, # Prepare for showing open/closed stacked
    displayedValue: current,
    difference: trend,
    trend_class: trend_class,
    arrow: 'icon-arrow-' + trend_class
  )
end
