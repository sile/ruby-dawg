require 'set'

module Dawg
  class NodeAllocator
    def initialize
      @head = 0x100
      @used = Set.new
      @nexts = Array.new
      @prevs = Array.new
    end
    
    def allocate(labels)
      front = labels[0]
      cur = @nexts[@head] || @head+1

      while true
        base = cur - front
        if(can_allocate?(base, labels))
          allocate_impl(base, labels)
          return base
        end
        
        cur = @nexts[cur] || cur+1
      end
    end

    def can_allocate?(base, labels)
      return false if @used.member?(base)
      return labels.all?{|x| @nexts[base+x] != -1 }
    end

    def allocate_impl(base, labels)
      @used.add(base)
      labels.each do |x|
        i = base+x
        next_i = @nexts[i] || i+1
        prev_i = @prevs[i] || i-1
        @nexts[prev_i] = next_i
        @prevs[next_i] = prev_i

        @nexts[i] = @prevs[i] = -1
      end
    end
  end
end
