# coding: UTF-8

require 'colorize'

require "./lib/models/item"
require "./lib/models/item_property"
require "./lib/models/link"
require "./lib/models/link_property"
require "./lib/command"


# Public: Model for working with agents.
#
# Examples
#
#   room = Item.new(name => 'a room', description => 'a room')
#   player = Agent.new(name => 'player1', description => 'a player', item => room)
#
class Agent < Sequel::Model
  plugin :validation_helpers
  many_to_one :item
  set_schema do
    primary_key :id
    foreign_key :item_id, :items
    string :name, :null=>false
    string :description, :text=>true
  end

  attr_reader :connection
  attr_writer :connection

  def validate
    super
    validates_presence [:name, :item]
  end

  def look(what = '')
    case what.downcase
    when '', 'here'
      connection.puts self.item.description
      connection.puts self.item.collect_exits
    when 'm', 'me', 's', 'self'
      connection.puts (self.description || "Nothing special.")
    else
      connection.puts "That isn't here to look at."
    end
  end

  def move(direction)
    link = Link.where(:src_item_id => self.item.id, Sequel.function(:lower, :name) => direction.downcase).first
    if !link.nil?
      self.item = Item.where(:id => link.dst_item_id).first
      @exits = Link.where(:src_item_id => self.item.id)
      return true
    else
      return false
    end
  end

  def repl(text)
    @command = Command.new unless !@command.nil?
    @command.last = text
    @command.parse_command
    @exits = self.item.exits unless !@exits.nil?

    # check exits, triggers, etc
    case @command.last.to_s.downcase
    when *@exits.collect{|e| e.name.downcase }
      move(@command.last.to_s)
      look
      return
    end

    case @command.head.to_s.downcase
    when 'l', 'look'
      look(@command.params)
    when 'q', 'quit'
      connection.puts "Quitting."
      connection.close
    # todo handle spaced exits, go and goto
    when *@exits.collect{|e| e.name.downcase }
      move(@command.head.to_s)
    else
      connection.puts "Unknown command: '#{@command.last.to_s}'"
    end
  end
end

Agent.create_table unless Agent.table_exists?
