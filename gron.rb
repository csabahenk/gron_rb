module Gron

  class Gron

    private_class_method def self.gron tree, cursor=[], &cbk
      if Enumerable === tree
        cbk.call cursor, tree.class.new
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

  def self.ungron enum
    tree = {root: nil}
    enum.each do |cursor, entry|
      if Enumerable === entry and ![{},[]].include? entry
        raise ArgumentError, "invalid #{entry.class} entry" + case entry
        when Array, Hash
          " of size #{entry.size} (should be empty)"
        else
          ": should be Hash or Array"
        end
      end

      stree = tree
      ([:root] + cursor).then do |xc|
        xc[0...-1].each_with_index { |k,i|
          stree[k] ||= case xc[i+1]
          when Integer
            []
          else
            {}
          end
          stree = stree[k]
        }
        leaf = stree[xc.last]
        if leaf
          unless leaf.class === entry
            raise TypeError, "entry at #{cursor} is a #{leaf.class}, cannot be changed to #{entry.class}"
          end
          if !Enumerable === entry and leaf != entry
            raise ArgumentError, "identity of entry at #{cursor} is already set"
          end
        else
          stree[xc.last] = entry
        end
      end
    end

    tree[:root]
  end

end
