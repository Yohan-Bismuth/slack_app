require 'slack-ruby-client'

$piIndex = -1
$team = ["y.bismuth", "s.pook", "n.fraison", "m.lachkar", "a.rabier", "a.savarin", "r.saissy"]
logger = Logger.new(STDOUT)

def getPi(logger)
  logger.info("Sending pi information")
  $team[$piIndex]
end

def getNextPi(logger)
  logger.info("Sending next pi information")
  $piIndex = ($piIndex + 1) % $team.length
  $team[$piIndex]
end

def getPreviousPi(logger)
  logger.info("Sending previous pi information")
  $piIndex = ($piIndex -1) % $team.length
  $team[$piIndex]
end

def timeToRemind?(logger)
  time = Time.new
  logger.info("Current time : #{time}")
  time.hour == 9 &&
    !time.saturday? &&
    !time.sunday?
end

def remind(client, channel_id, logger)
  while true
    sleep(3600)
    if timeToRemind?(logger)
      logger.info("Sending a reminder")
      client.chat_postMessage(channel: channel_id, text: "Lake new PI is #{getNextPi(logger)} today", as_user: true)
    end
  end
end

Slack.configure do |config|
  config.token = ENV['SLACK_TOKEN']
  config.logger = logger
  config.logger.level = Logger::INFO
end

web_client = Slack::Web::Client.new()
rtm_client = Slack::RealTime::Client.new()

rtm_client.on :hello do
  puts "Successfully connected, welcome '#{rtm_client.self.name}' to the '#{rtm_client.team.name}' team at https://#{rtm_client.team.domain}.slack.com."
end

rtm_client.on :message do |data|
  case data.text
  when 'lakebot pi' then
    rtm_client.message channel: data.channel, text: "Lake PI is #{getPi(logger)} today"
  when 'lakebot nextpi' then
    rtm_client.message channel: data.channel, text: "Lake new PI is #{getNextPi(logger)} today"
  when 'lakebot previouspi' then
    rtm_client.message channel: data.channel, text: "Lake new PI is #{getPreviousPi(logger)} today"
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
reminder_thread=Thread.new{remind(web_client, lake_channel_id, logger)}

[ reminder_thread, rtm_client_thread ].each do |t|
  t.join
end
