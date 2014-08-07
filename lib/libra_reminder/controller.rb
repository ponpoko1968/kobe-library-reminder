# coding: utf-8

module LibraReminder

  class Controller

    def initialize(config)
      @config = config
    end

    def books_from_library(config)
      Scraper.fetchBooksOnLoan()
    end


    def consistent_with_db(books)
      Book.update_all to_be_deleted:true
      books.each do |book|
        recs =  Book.where(book_id: book[:book_id])
        if recs.empty?
          Book.create!(book_id: book[:book_id], book_name: book[:book_name], deadline: book[:deadline] )
        else
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
            if dbbook.to_be_deleted == "t" #図書館側で削除されている
              if gcal.delete_event(dbbook.event_id) #カレンダーを消して
                logger.info("'#{dbbook.book_name}' is deleted from google calendar")
                book.destroy    #DBからも消す
                logger.info("'#{dbbook.book_name}' is deleted from DB")
                next
              end
            end
            # 日付が不一致(図書館側で延長手続きされた)
            if dbbook.deadline.to_date != Date.parse(event.data.start.date)
              gcal.update_event(dbbook)
              logger.info("'#{dbbook.book_name}'is updated #{Date.parse(event.data.start.date)} => #{dbbook.deadline}")
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
