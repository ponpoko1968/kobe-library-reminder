# -*- coding: utf-8 -*-
require 'fileutils'
require 'active_record'

module LibraReminder
  module DB
    def self.prepare
      database_path = File.join(ENV['HOME'], '.libra_reminder', 'libra_reminder.db')
      connect_database database_path
      create_table_if_not_exists database_path
    end
    def self.connect_database(path)
      spec = {adapter: 'sqlite3', database: path }
      ActiveRecord::Base.establish_connection spec
    end

    def self.create_table_if_not_exists(path)
      create_database_path path
      connection = ActiveRecord::Base.connection

      return if connection.table_exists?(:books)

      connection.create_table :books do |t|
        t.column :book_id, :string, null: false, limit: 64
        t.column :deadline, :datetime, null: false
        t.column :to_be_deleted, :bool, default: false, null: false
        t.column :book_name, :string, null:false
        t.column :event_id, :string
      end
      connection.add_index :books, :book_id
      connection.add_index :books, :event_id
    end
    
    def self.create_database_path(path)
      FileUtils.mkdir_p File.dirname(path)
    end
    private_class_method :connect_database, :create_table_if_not_exists, :create_database_path
  end
end
