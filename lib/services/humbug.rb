class Service::Humbug < Service
  self.title = "Zulip"
  url = 'https://zulip.com'
  logo_url = 'https://zulip.com/static/images/logo/zulip-icon-512x512.png'
  maintained_by :github => 'acrefoot'
  supported_by :email => 'support@zulip.com'

  # textboxes
  string :email
  string :api_key
  string :stream
  string :commit_stream
  string :issue_stream
  string :branches
  string :alternative_endpoint

  # checkboxes
  boolean :block_pull_requests
  boolean :block_issues
  boolean :block_commits

  # list of things approved for github's logging. See service.rb for more.
  white_list :email
  white_list :branches
  white_list :alternative_endpoint
  white_list :block_pull_requests
  white_list :block_issues
  white_list :block_commits

  # events handled by this github hook
  default_events :commit_comment, :create, :delete, :download, :follow, :fork,
    :fork_apply, :gist, :gollum, :issue_comment, :issues, :member, :public,
    :pull_request, :push, :team_add, :watch, :pull_request_review_comment,
    :status

  def receive_event
    puts data
    raise_config_error "Missing 'email'" if data['email'].to_s.empty?
    raise_config_error "Missing 'api_key'" if data['api_key'].to_s.empty?

    data['alternative_endpoint'] = data['alternative_endpoint'].to_s.strip

    if data['alternative_endpoint'].empty?
        url = 'https://zulip.com/api/v1/external/github'
    else
        url = data['alternative_endpoint'].to_s.strip
    end
    puts url
    puts data
    begin
        http.headers['User-Agent'] = 'ZulipGitHubWebhook'
        http.headers['Accept'] = 'application/json'
        res = http_post url,
          :email => data['email'],
          :api_key => data['api_key'],
          :stream => data['stream'],
          :commit_stream => data['commit_stream'],
          :issue_stream => data['issue_stream'],
          :branches => data['branches'],
          :block_pull_requests => data['block_pull_requests'],
          :block_issues => data['block_issues'],
          :block_commits => data['block_commits'],

          :event => event,
          :payload => generate_json(payload),
          # unspecified means an implicit version 1
          :github_payload_version => '2',
          :client => 'ZulipGitHubWebhook'



        if not res.success?
            raise_config_error ("Server returned status " + res.status.to_s +
                                ": " + res.body)
        end
    rescue Errno::ENOENT => e
        raise_missing_error (url + " could not be reached")
    end
  end
end
