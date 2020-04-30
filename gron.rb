#!/usr/bin/env ruby

module Gron

  module PRUNE
  end

  class Gron

    private_class_method def self.gron tree, cursor=[], &cbk
      if Enumerable === tree
        return if cbk.call(cursor, tree.class.new) == PRUNE
        case tree
        when Hash
          tree.each{|k,v| gron v, cursor+[k], &cbk }
        when Array
          tree.each_with_index{|v,i| gron v, cursor+[i], &cbk }
        else raise TypeError "can't handle class #{tree.class}"
        end
      else
        cbk.call cursor, tree
      end
      nil
    end

    def initialize tree
      @tree = tree
    end

    def gron &cbk
      return to_enum(__method__) unless cbk

      self.class.send :gron, @tree, [], &cbk
    end

  end

  def self.gron tree, &cbk
    Gron.new(tree).gron &cbk
  end

  class Ungron

    def initialize
      @tree = {root: nil}
      yield self if block_given?
    end

    def push cursor, entry
      if Enumerable === entry and ![{},[]].include? entry
        raise ArgumentError, "invalid #{entry.class} entry" + case entry
        when Array, Hash
          " of size #{entry.size} (should be empty)"
        else
          ": should be Hash or Array"
        end
      end

      subtree = @tree
      xc = [:root] + cursor
      xc[0...-1].each_with_index { |k,i|
        subtree[k] ||= case xc[i+1]
        when Integer
          []
        else
          {}
        end
        subtree = subtree[k]
      }
      leaf = subtree[xc.last]
      if leaf
        unless leaf.class === entry
          raise TypeError, "entry at #{cursor} is a #{leaf.class}, cannot be changed to #{entry.class}"
        end
        if not Enumerable === entry and leaf != entry
          raise ArgumentError, "identity of entry at #{cursor} is already set"
        end
      else
        subtree[xc.last] = entry
      end
      self
    end

    def callback
      proc { |a| push *a; nil }
    end

    def << pr
      push *pr
    end

    def splat cursor, obj
      ::Gron.gron(obj) { |c,v| push cursor + c, v }
      self
    end

    def tree
      @tree[:root]
    end

  end

  def self.ungron enum
    u = Ungron.new
    enum.each &u.callback
    u.tree
  end

end

if __FILE__ == $0

  require 'optparse'
  require 'json'

  ung = false
  OptionParser.new do |o|
    o.on("--ungron", "-u", "Reverse the operation (turn assignments back into JSON)") { ung = true }
  end.parse!

  case ung
  when false
    Gron.gron(JSON.load $<) { |*pr| puts pr.to_json }
  when true
    u = Gron::Ungron.new
    $<.each { |l| u << JSON.load(l) }
    puts u.tree.to_json
  end

end
