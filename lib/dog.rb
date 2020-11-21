require 'pry'
class Dog
    attr_accessor :name, :breed
    attr_reader :id

    def initialize(id:nil, name:, breed:)
        @id = id
        @name = name
        @breed = breed
    end

    def self.create_table
        sql = <<-SQL
        CREATE TABLE IF NOT EXISTS dogs
        (id INTEGER PRIMARY KEY, name TEXT, breed TEXT)
        SQL
        DB[:conn].execute(sql)
    end

    def self.drop_table
        sql = <<-SQL
        DROP TABLE IF EXISTS dogs
        SQL
        DB[:conn].execute(sql)
    end

    def save
        if self.id
            self.update
        else
        sql = <<-SQL
        INSERT INTO dogs (name, breed)
        VALUES (?, ?)
        SQL
        DB[:conn].execute(sql, self.name, self.breed)
        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
        end
        self
    end

    def update
        sql = <<-SQL
        UPDATE dogs SET name = ?, breed = ? WHERE id = ?
        SQL
        DB[:conn].execute(sql, self.name, self.breed, self.id)
    end

    def self.create(hash)
           dog = self.new(
               name: hash.fetch(:name), 
               breed: hash.fetch(:breed))
           dog.save
    end

    def self.new_from_db(row)
        dog = self.new(id: row[0], name: row[1], breed: row[2])
        dog
    end

    def self.find_by_id(id)
        sql = <<-SQL
        SELECT * FROM dogs WHERE id = ?
        SQL
        DB[:conn].execute(sql, id).map {|row| self.new_from_db(row)}.first
    end

    def self.find_or_create_by(hash)
        dog = DB[:conn].execute("
        SELECT * FROM dogs 
        WHERE name = ? AND breed = ?", hash.fetch(:name), hash.fetch(:breed))
        if !dog.empty?
            dog_info = dog[0]
            dog = self.new(id: dog_info[0],name: dog_info[1],breed: dog_info[2])
        else self.create(hash)
        end
    end

    def self.find_by_name(name)
        sql = <<-SQL
        SELECT * FROM dogs WHERE name = ?
        SQL
        DB[:conn].execute(sql, name).map {|row| self.new_from_db(row)}.first
    end
end