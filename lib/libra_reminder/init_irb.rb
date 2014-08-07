require 'libra_reminder/scraper'



require 'libra_reminder'
LibraReminder::DB.prepare
config = YAML.load_file(File.join(ENV['HOME'], '.libra_reminder', 'config.yaml'))
book=LibraReminder::Book.order('book_name')[0]
gcal = LibraReminder::Gcal.new(config)
event_id=gcal.create_event(book)


LibraReminder::Book.create!(book_id:'1', book_name: 'book1', deadline: Date.parse('20140810') )


LibraReminder::Book.where(to_be_deleted:false)
LibraReminder::Book.where(to_be_deleted:true)
LibraReminder::Book
