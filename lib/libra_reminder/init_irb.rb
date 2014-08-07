require 'libra_reminder/scraper'

config = YAML.load_file(File.join(ENV['HOME'], '.libra_reminder', 'config.yaml'))
page = LibraReminder::Scraper.fetchBooksOnLoan(config)
nil
