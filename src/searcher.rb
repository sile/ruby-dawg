require 'stringio'

module Dawg
  class Searcher
    def initialize(index_path)
      bytes = open(index_path, 'rb').read
      @nodes = bytes.unpack("N*")
    end

    # key = string or stringio
    def member?(key)
      index = 0
      key.each_byte do |arc|
        next_index = base(index) + arc
        return false if chck(next_index) != arc
        index = next_index
      end
      return is_terminal(index)
    end

    def get_id(key)
      id = 0
      index = 0
      key.each_byte do |arc|
        next_index = base(index) + arc
        return nil if chck(next_index) != arc
        index = next_index
        id += id_offset(index)
      end
      return is_terminal(index) ? id : nil
    end

    def each_common_prefix(key)
      i = 0
      id = 0
      index = 0
      key.each_byte do |arc|
        yield i, id+1 if is_terminal(index)

        next_index = base(index) + arc
        return nil if chck(next_index) != arc
        index = next_index

        id += id_offset(index)
        i += 1
      end
      yield i, id+1 if is_terminal(index)
      nil
    end

    def is_terminal(index)
      (@nodes[index*2] >> 31) != 0
    end

    def base(index)
      @nodes[index*2] & 0x7FFFFFFF
    end

    def chck(index)
      @nodes[index*2+1] & 0xFF
    end

    def sibling_total(index)
      @nodes[index*2+1] >> 8
    end

    def id_offset(index)
      (is_terminal(index) ? 1 : 0) + sibling_total(index)
    end
  end
end
