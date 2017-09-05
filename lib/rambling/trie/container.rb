module Rambling
  module Trie
    # Wrapper on top of trie data structure.
    class Container
      extend ::Forwardable
      include ::Enumerable

      delegate [
        :[],
        :as_word,
        :children,
        :children_tree,
        :compressed?,
        :each,
        :to_a,
        :has_key?,
        :inspect,
        :letter,
        :parent,
        :size,
        :to_s
      ] => :root

      # The root node of this trie.
      # @return [Node] the root node of this trie.
      attr_reader :root

      # Creates a new trie.
      # @param [Node] root the root node for the trie
      # @param [Compressor] compressor responsible for compressing the trie
      # @yield [Container] the trie just created.
      def initialize root, compressor
        @root = root
        @compressor = compressor

        yield self if block_given?
      end

      # Adds a word to the trie, without altering the passed word.
      # @param [String] word the word to add the branch from.
      # @return [Node] the just added branch's root node.
      # @raise [InvalidOperation] if the trie is already compressed.
      # @see RawNode#add
      # @see CompressedNode#add
      # @note Avoids altering the contents of the word variable.
      def add word
        root.add word.clone
      end

      # Compresses the existing tree using redundant node elimination. Marks
      # the trie as compressed.
      # @return [Container] self
      # @note Only compresses tries that have not already been compressed.
      def compress!
        self.root = compressor.compress root unless root.compressed?
        self
      end

      # Checks if a path for a word or partial word exists in the trie.
      # @param [String] word the word or partial word to look for in the trie.
      # @return [Boolean] `true` if the word or partial word is found, `false`
      #   otherwise.
      # @see RawNode#partial_word?
      # @see CompressedNode#partial_word?
      def partial_word? word = ''
        root.partial_word? word.chars
      end

      # Checks if a whole word exists in the trie.
      # @param [String] word the word to look for in the trie.
      # @return [Boolean] `true` only if the word is found and the last
      #   character corresponds to a terminal node, `false` otherwise.
      # @see RawNode#word?
      # @see CompressedNode#word?
      def word? word = ''
        root.word? word.chars
      end

      # Returns all words that start with the specified characters.
      # @param [String] word the word to look for in the trie.
      # @return [Array<String>] all the words contained in the trie that start
      #   with the specified characters.
      # @see RawNode#scan
      # @see CompressedNode#scan
      def scan word = ''
        root.scan(word.chars).to_a
      end

      # Returns all words within a string that match a word contained in the
      # trie.
      # @param [String] phrase the string to look for matching words in.
      # @return [Enumerator<String>] all the words in the given string that
      #   match a word in the trie.
      # @yield [String] each word found in phrase.
      # @see Node#words_within
      def words_within phrase
        words_within_root(phrase).to_a
      end

      # Checks if there are any valid words in a given string.
      # @param [String] phrase the string to look for matching words in.
      # @return [Boolean] `true` if any word within phrase is contained in the
      #   trie, `false` otherwise.
      # @see Container#words_within
      def words_within? phrase
        words_within_root(phrase).any?
      end

      def longest_words_within phrase
        longest_words_within_root(phrase).to_a
      end

      def words_prefix phrase
        words_prefix_root(phrase).to_a
      end

      def longest_words_prefix phrase
        longest_words_prefix_root(phrase)
      end

      # Compares two trie data structures.
      # @param [Container] other the trie to compare against.
      # @return [Boolean] `true` if the tries are equal, `false` otherwise.
      def == other
        root == other.root
      end

      alias_method :include?, :word?
      alias_method :match?, :partial_word?
      alias_method :words, :scan
      alias_method :<<, :add

      private

      attr_reader :compressor
      attr_writer :root

      def words_within_root phrase
        return enum_for :words_within_root, phrase unless block_given?

        chars = phrase.chars
        0.upto(chars.length - 1).each do |starting_index|
          new_phrase = chars.slice starting_index..(chars.length - 1)
          root.match_prefix new_phrase do |word|
            yield word
          end
        end
      end

      def words_prefix_root phrase
        return enum_for :words_prefix_root, phrase unless block_given?

        chars = phrase.chars
        new_phrase = chars.slice 0..(chars.length - 1)
        root.match_prefix new_phrase do |word|
          yield word
        end
      end

      def longest_words_within_root phrase
        return enum_for :longest_words_within_root, phrase unless block_given?

        chars = phrase.chars
        starting_index = 0
        loop do
          new_phrase = chars.slice starting_index..(chars.length - 1)
          words = root.match_prefix(new_phrase)
          longest_word = nil
          words.each do | word |
            if longest_word.nil?
              longest_word = word
            elsif longest_word.size < word.size
              longest_word = word
            end
          end
          if longest_word.nil?
            starting_index += 1
          else
            yield longest_word
            starting_index += longest_word.size
          end
          break if starting_index >= chars.length
        end
      end

      def longest_words_prefix_root phrase
        chars = phrase.chars

        new_phrase = chars.slice 0..(chars.length - 1)
        words = root.match_prefix(new_phrase)
        longest_word = nil
        words.each do | word |
          if longest_word.nil?
            longest_word = word
          elsif longest_word.size < word.size
            longest_word = word
          end
        end
        longest_word
      end
    end
  end
end
