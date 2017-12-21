# coding: utf-8
require 'optparse'

module LibraReminder

  class Controller
    def self.run(argv)
      new(argv).execute
    end

    def initialize(argv)
      @argv = argv
    end

    def execute
      options = {}
      parser = create_option_parser(options)
      parser.parse!(@argv)
      if options[:path_to_config]
        path_to_config = options[:path_to_config]
      else
        path_to_config = File.join(ENV['HOME'], '.libra_reminder', 'config.yaml')
      end
      @config = YAML.load_file(path_to_config)

      DB.prepare

      books_on_web = books_from_library(@config)
      consistent_with_db(books_on_web)
      consistent_with_gcal
    end

    def create_option_parser(options)
      OptionParser.new do |opt|
        opt.banner = "Usage: #{opt.program_name} [-h|--help][-v|--version] [-c|--config <path-to-config.yaml>]"
        opt.separator ''
        opt.separator "#{opt.program_name} Availavle Commands:"
        # help
        opt.on_head('-c VAL','--config=VAL','specify path to config.yaml') do |v|
          options[:path_to_config] = v
        end
        # help
        opt.on_head('-h','--help','Show this message') do |v|
          puts opt.help
          exit
        end
        # version
        opt.on_head('-v','--version','show program version') do |v|
          opt.version = LibraReminder::VERSION
          puts opt.version
          exit
        end
      end
    end


    def books_from_library(config)
      Scraper.fetchBooksOnLoan(config)
    end


    def consistent_with_db(books)
      Book.update_all to_be_deleted:true
      books.each do |book|
        recs =  Book.where(book_id: book[:book_id])
        if recs.empty?
          Book.create!(book_id: book[:book_id], book_name: book[:book_name], deadline: book[:deadline] )
        else
          recs[0].deadline = book[:deadline]
          recs[0].to_be_deleted = false
          recs[0].save
        end
      end
      nil
    end

    def consistent_with_gcal
      logger = Logger.new STDOUT
      logger.level = Logger::INFO

      gcal = Gcal.new(@config)
      Book.all.each do |book|
        logger.info(book.id)
        if book.event_id # 一度カレンダーに登録されている
          logger.info(book.event_id)
          event =  gcal.find_event(book)
          if event
            dbbook = Book.where(event_id: event.data.id)[0]
            if dbbook != nil && dbbook.to_be_deleted == "t" #図書館側で削除されている
              if gcal.delete_event(dbbook.event_id) #カレンダーを消して
                logger.info("'#{dbbook.book_name}' is deleted from google calendar")
                book.destroy    #DBからも消す
                logger.info("'#{dbbook.book_name}' is deleted from DB")
                next
              end
            end
            # 日付が不一致(図書館側で延長手続きされた)
            begin 
              if dbbook.deadline.to_date != Date.parse(event.data.start.date)
                gcal.update_event(dbbook)
                logger.info("'#{dbbook.book_name}'is updated #{Date.parse(event.data.start.date)} => #{dbbook.deadline}")
              end
              rescue => e
                logger.info("#{e}")
            end
          end
        else                    #一度も登録されていない
          event_id = gcal.create_event(book)
          logger.info(event_id)
          if event_id
            book.event_id = event_id
            book.save
          end
        end
      end
      nil
    end
  end
end
