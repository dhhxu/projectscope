class Project < ActiveRecord::Base
  has_one :pull_request
  has_one :slack_metric
  has_many :slack_data_points, through: :slack_metric 
  
  def get_slack_data
    client = Slack::Web::Client.new(token: ENV['SLACK_API_TOKEN'])
    users = client.users_list.members
    users.each do |user|
      unless user.name == "slackbot"
        num_messages = client.search_all(query: "from:@#{user.name}").messages.total
        slack_data_point = self.slack_data_points.find_by user: user.name
        if slack_data_point
          slack_data_point.update_attributes(:messages => num_messages)
        else
          self.slack_data_points.create(user: user.name, messages: num_messages)
        end
      end
    end
  end

end
