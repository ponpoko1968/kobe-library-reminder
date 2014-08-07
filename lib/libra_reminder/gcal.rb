# -*- coding: utf-8 -*-
require 'google/api_client'
require "yaml"
require "time"

module LibraReminder
  class Gcal
    def initialize(config)
      @config = config
      @oauth_yaml = YAML.load_file(config['oauth_yaml'])
      @client = Google::APIClient.new( application_name:'LibraReminder', application_version: VERSION)
      @client.authorization.client_id = @oauth_yaml["client_id"]
      @client.authorization.client_secret = @oauth_yaml["client_secret"]
      @client.authorization.scope = @oauth_yaml["scope"]
      @client.authorization.refresh_token = @oauth_yaml["refresh_token"]
      @client.authorization.access_token = @oauth_yaml["access_token"]
      @cal = @client.discovered_api('calendar', 'v3')

    end

    def create_event(book)
      # 返値はカレンダーID
      d = book['deadline'].to_datetime
      ds = sprintf( "%04d-%02d-%02d",d.year,d.month,d.day)
      event = {'calendarId' => @config['calendar_id'],
                'summary' => book['book_name'],
                'start' => {
                            'date' => ds
                           },
                'end' => {
                            'date' => ds
                           }
               }

      result = @client.execute(:api_method => @cal.events.insert,
                        :parameters => {'calendarId' => @config['calendar_id']},
                        :body => JSON.dump(event),
                        :headers => {'Content-Type' => 'application/json'})
      result.data.id
    end

    def find_event(book)
    end

    def update_event(book)
      # findして返却日が合致していなければカレンダーの日付を更新
    end

    def delete_event(event_id)
      result = @client.execute(:api_method => @cal.events.delete,
                               :parameters => {'calendarId' => @config['calendar_id'], 'eventId' => event_id})
      result.status == 204
    end
    
  end
end
