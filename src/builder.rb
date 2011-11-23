require 'kconv'

module Dawg
  class Builder
    class Node
      attr_accessor :label
      attr_accessor :child
      attr_accessor :sibling
      attr_accessor :is_terminal
      attr_accessor :child_total
      attr_accessor :sibling_total
      
      def initialize (label)
        @label = label
        @is_terminal = false
        @child = nil
        @sibling = nil
        @child_total = 0
        @sibling_total = 0
        @hash = -1
      end

      def self.calc_total(node)
        return 0 if node.nil?
        
        (node.is_terminal ? 1 : 0) + node.child_total + node.sibling_total
      end

      def calc_child_total
        calc_total @child
      end

      def calc_sibling_total
        calc_total @sibling
      end

      def hash
        if @hash == -1
          @hash = 
            @label.hash ^
            @is_terminal.hash ^
            (@child.hash*7) ^
            (@sibling.hash*13)
          
          @child_total = calc_child_total
          @sibling_total = calc_sibling_total
        end
        @hash
      end

      def eql?(n)
        @chlid.equal?(n.child) && 
          @siblng.equal?(n.sibling) &&
          @label == n.label &&
          @is_termianl == n.is_terminal
      end
    end

    def build(keys)
      keys = keys.sort.uniq
      
      root = Node.new(0)
      root.eql?(Node.new(10))
      memo = Hash.new
    end
  end
end


Dawg::Builder.new.build([1,2,3])
