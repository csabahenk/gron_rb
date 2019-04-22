module Gron

  def self.gron tree, cursor=[], &cbk
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

end
