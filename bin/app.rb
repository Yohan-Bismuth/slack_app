require 'slack-ruby-client'

$piIndex = -1
$team = ["y.bismuth", "s.pook", "n.fraison", "m.lachkar", "a.rabier", "a.savarin", "r.saissy"]

def getPi()
  $team[$piIndex]
end

def getNextPi()
  $piIndex = ($piIndex + 1) % $team.length
  $team[$piIndex]
end

def remind(client, channel_id)
  time = Time.new
  while true
    if time.hour == 8
      client.chat_postMessage(channel: channel_id, text: "@here Lake new PI is #{getNextPi()} today", as_user: true)
    end
    sleep(3600)
  end
end

Slack.configure do |config|
  # lakebot token
  config.token = ENV['SLACK_TOKEN']
  config.logger = Logger.new(STDOUT)
  config.logger.level = Logger::INFO
end

web_client = Slack::Web::Client.new
rtm_client = Slack::RealTime::Client.new()

rtm_client.on :hello do
  puts "Successfully connected, welcome '#{rtm_client.self.name}' to the '#{rtm_client.team.name}' team at https://#{rtm_client.team.domain}.slack.com."
end

rtm_client.on :message do |data|
  case data.text
  when 'lakebot pi' then
    rtm_client.message channel: data.channel, text: "Lake PI is #{getPi()} today"
  when 'lakebot nextpi' then
    rtm_client.message channel: data.channel, text: "@here Lake new PI is #{getNextPi()} today"
  when /^lakebot / then
    rtm_client.message channel: data.channel, text: "Wrong request"
  end
end

rtm_client.on :close do |_data|
  puts "Rtm_Client is about to disconnect"
end

rtm_client.on :closed do |_data|
  puts "Rtm_Client has disconnected successfully!"
end

lake_channel_id = web_client.groups_info(channel: "#lake-secret").group["id"]
rtm_client_thread=Thread.new{rtm_client.start!}
reminder_thread=Thread.new{remind(web_client, lake_channel_id)}

[ reminder_thread, rtm_client_thread ].each do |t|
  t.join
end
