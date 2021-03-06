class PullRequest < ActiveRecord::Base
  belongs_to :project
  validate :repo_name_is_appropriate
  
  def get_data
    begin
      client = Octokit::Client.new(:access_token => ENV['GITHUB_KEY'])
      client.auto_paginate = true
      
      comments = client.pull_requests_comments self.repo
      closed_prs = client.pulls self.repo, :state => 'closed'
      open_prs = client.pulls self.repo, :state => 'open'
      total_prs = closed_prs.length + open_prs.length
      
      comments_hash = {}
      comments.each do |comment|
          url = comment.pull_request_url
          regex = /^https:\/\/api.github.com\/repos\/[^\/]+\/[^\/]+\/pulls\/(\d+)$/
          if url =~ regex
              pull_no = $1
          end
          pull_no = pull_no.to_i
          
          if comments_hash.has_key? pull_no
              comments_hash[pull_no] += 1
          else
              comments_hash[pull_no] = 1
          end
      end
      
      yellow_cutoff = 1
      green_cutoff = 2
      
      pulls_with_comments = comments_hash.values
      red = total_prs - pulls_with_comments.length
      yellow = pulls_with_comments.count {|x| x == yellow_cutoff}
      green = pulls_with_comments.count {|x| x >= green_cutoff}
      score = (green + yellow * 0.5)/ (green + red + yellow)
      pr_hash = {red: red, yellow: yellow, green: green, total: red+yellow+green, score: score}
    rescue Octokit::InvalidRepository, Octokit::NotFound
      pr_hash = {red: -1, yellow: -1, green: -1, total: -1, score: -1}
    ensure
      self.update_attributes(pr_hash)
    end
    
  end
  
  def message
      if self.total >= 0
        "Pull Requests: #{self.total}"
      else
        'Pull Requests:'
      end
  end
  
  def url
      if self.repo
        "https://github.com/#{self.repo}"
      else
        ''
      end
  end
  
  def repo_name_is_appropriate
    self.repo.chomp!('/')
    self.repo.chomp!('.git')
  end
  
end
