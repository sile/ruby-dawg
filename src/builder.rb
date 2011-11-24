require 'kconv'
require 'stringio'

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

      def children
        children = Array.new
        child = @child
        
        while child
          children << child
          child = child.sibling
        end

        children.reverse
      end

      def calc_total(node)
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
        @child.equal?(n.child) && 
          @sibling.equal?(n.sibling) &&
          @label == n.label &&
          @is_terminal == n.is_terminal
      end
    end

    attr_accessor :root
    
    def initialize(options={})
      @show_progress = options[:show_progress]
      @show_interval = options[:show_interval] || 50000
      
      @root = Node.new(0)
    end

    def build_from_file(file)
      keys = Array.new
      open(file).each do |line|
        keys << line.strip
      end
      build(keys)
    end

    def build(keys)
      root = Node.new(0)
      memo = Hash.new

      puts "# Build On-Memoery Trie: #{keys.size} keys" if @show_progress
      keys.each_with_index do |key,i|
        puts " # #{i}" if @show_progress && i%@show_interval == 0
        
        insert(StringIO.new(key), root, memo)
      end
      puts " # #{keys.size}" if @show_progress
      puts " # DONE"

      @root = share(root, memo)
      self
    end

    def share(node, memo)
      return nil if node.nil?
      
      return memo[node] if memo.key?(node)
      
      node.child = share(node.child, memo)
      node.sibling = share(node.sibling, memo)
      return memo[node] if memo.key?(node)

      return memo[node] = node
    end

    def push_child(key, parent)
      if key.eof?
        parent.is_terminal = true
      else
        node = Node.new(key.getc)
        node.sibling = parent.child
        parent.child = node
        push_child(key, node)
      end
    end

    def insert(key, parent, memo)
      node = parent.child
      label = key.getc

      if node.nil? || key.eof? || label != node.label
        parent.child = share(node, memo)
        key.ungetc(label)
        push_child(key, parent)
      else
        insert(key, node, memo)
      end
    end

    def member?(key)
      key = StringIO.new(key)
      parent = @root
      node = parent.child
      
      while true
        return parent.is_terminal if key.eof?
        return false if node.nil?

        label = key.getc
        if label == node.label
          parent = node
          node = parent.child
        else
          key.ungetc(label)
          node = node.sibling
        end
      end
    end
  end

  class DA
    class Node
      attr_accessor :index
      attr_accessor :base
      attr_accessor :node
      
      def initialize(parent_base, node)
        @base = 0
        @node = node
        @index = parent_base + node.label
      end

      def pack
        n1 = (@base & 0x7FFFFFFF) | ((@node.is_terminal ? 1 : 0) << 31)
        n2 = (@node.label & 0xFF) | (@node.sibling_total << 8)
        [n1,n2].pack("N2")
      end
    end

    def initialize
      @nodes = Array.new
      @memo = Hash.new
      @alloca = NodeAllocator.new
    end

    def build_impl(node)
      trie = node.node
      children = trie.children
      
      if @memo.key?(trie)
        node.base = @memo[trie]
        @nodes[node.index] = node
      elsif children.size==0
        @nodes[node.index] = node
      else
        base = @alloca.allocate(children.map{|c| c.label})
        @memo[trie] = base
        node.base = base
        @nodes[node.index] = node
        
        children.each do |child|
          build_impl(Node.new(base, child))
        end
      end
    end

    def build (trie, output_file)
      build_impl(Node.new(0,trie))
      
      max_base = 0
      open(output_file,'wb') do |out|
        @nodes.each do |node|
          if node
            max_base = node.base if max_base < node.base
            out.write node.pack
          else
            out.write [0,0].pack("N2")
          end
        end

        (@nodes.size..(max_base+0xFF)).each do |i|
          out.write [0,0].pack("N2")
        end
      end
      
      :done
    end
  end
end

#keys = open(ARGV[0]).read.split("\n")
#Dawg::Builder.new(:show_progress => true).build(keys)
