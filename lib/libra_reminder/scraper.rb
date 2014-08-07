# coding: utf-8

require 'mechanize'
require 'logger'

module LibraReminder
  class Scraper
    def self.fetchBooksOnLoan(config)
      cookie_path = config['cookie_file_path']

      agent = Mechanize.new

      logger = Logger.new STDOUT
      logger.level = Logger::INFO
      agent.log = logger

      # UA 偽装
      agent.user_agent_alias = 'Windows IE 7'

      # cookie をファイルから読み込む
      agent.cookie_jar.load cookie_path if File.exist? cookie_path


      uri = URI.parse config['uri']
      top = agent.get uri
      page = agent.page
      if page.root.css(".loginmess") 
        logger.debug 'not logged in'
        username = config ['username']
        password = config ['password']
        f = top.forms[0]
        f['user[login]'] = username
        f['user[passwd]'] = password
        f['act_login'] = ''
        top = f.submit
      end
      page = agent.page
      #print page.root
      table = page.search("div[@class='table_wrapper lending']")
      records = []
      if table
        table.xpath('//tr').each do |row|
          cols = row.search('td')
          unless cols.empty?
            name = cols[2].text
            deadline = Date.parse(cols[3].text)
            bookId = cols[7].text.split('/')[1].strip.chomp
            print "#{name}|#{deadline}|#{bookId}\n"
            records << {name: name, deadline: deadline, bookId: bookId }
          end
        end
        
      else
        nil
      end
      records
    end
  end
end
