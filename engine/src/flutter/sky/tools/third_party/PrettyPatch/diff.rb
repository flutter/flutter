module HTMLDiff

  Match = Struct.new(:start_in_old, :start_in_new, :size)
  class Match
    def end_in_old
      self.start_in_old + self.size
    end
    
    def end_in_new
      self.start_in_new + self.size
    end
  end
  
  Operation = Struct.new(:action, :start_in_old, :end_in_old, :start_in_new, :end_in_new)

  class DiffBuilder

    def initialize(old_version, new_version)
      @old_version, @new_version = old_version, new_version
      split_inputs_to_words
      index_new_words
    end

    def split_inputs_to_words
      @old_words = explode(@old_version)
      @new_words = explode(@new_version)
    end

    def index_new_words
      @word_indices = Hash.new { |h, word| h[word] = [] }
      @new_words.each_with_index { |word, i| @word_indices[word] << i }
    end

    def operations
      position_in_old = position_in_new = 0
      operations = []
      
      matches = matching_blocks
      # an empty match at the end forces the loop below to handle the unmatched tails
      # I'm sure it can be done more gracefully, but not at 23:52
      matches << Match.new(@old_words.length, @new_words.length, 0)
      
      matches.each_with_index do |match, i|
        match_starts_at_current_position_in_old = (position_in_old == match.start_in_old)
        match_starts_at_current_position_in_new = (position_in_new == match.start_in_new)
        
        action_upto_match_positions = 
          case [match_starts_at_current_position_in_old, match_starts_at_current_position_in_new]
          when [false, false]
            :replace
          when [true, false]
            :insert
          when [false, true]
            :delete
          else
            # this happens if the first few words are same in both versions
            :none
          end

        if action_upto_match_positions != :none
          operation_upto_match_positions = 
              Operation.new(action_upto_match_positions, 
                  position_in_old, match.start_in_old, 
                  position_in_new, match.start_in_new)
          operations << operation_upto_match_positions
        end
        if match.size != 0
          match_operation = Operation.new(:equal, 
              match.start_in_old, match.end_in_old, 
              match.start_in_new, match.end_in_new)
          operations << match_operation
        end

        position_in_old = match.end_in_old
        position_in_new = match.end_in_new
      end
      
      operations
    end

    def matching_blocks
      matching_blocks = []
      recursively_find_matching_blocks(0, @old_words.size, 0, @new_words.size, matching_blocks)
      matching_blocks
    end

    def recursively_find_matching_blocks(start_in_old, end_in_old, start_in_new, end_in_new, matching_blocks)
      match = find_match(start_in_old, end_in_old, start_in_new, end_in_new)
      if match
        if start_in_old < match.start_in_old and start_in_new < match.start_in_new
          recursively_find_matching_blocks(
              start_in_old, match.start_in_old, start_in_new, match.start_in_new, matching_blocks) 
        end
        matching_blocks << match
        if match.end_in_old < end_in_old and match.end_in_new < end_in_new
          recursively_find_matching_blocks(
              match.end_in_old, end_in_old, match.end_in_new, end_in_new, matching_blocks)
        end
      end
    end

    def find_match(start_in_old, end_in_old, start_in_new, end_in_new)

      best_match_in_old = start_in_old
      best_match_in_new = start_in_new
      best_match_size = 0
      
      match_length_at = Hash.new { |h, index| h[index] = 0 }
      
      start_in_old.upto(end_in_old - 1) do |index_in_old|

        new_match_length_at = Hash.new { |h, index| h[index] = 0 }

        @word_indices[@old_words[index_in_old]].each do |index_in_new|
          next  if index_in_new < start_in_new
          break if index_in_new >= end_in_new

          new_match_length = match_length_at[index_in_new - 1] + 1
          new_match_length_at[index_in_new] = new_match_length

          if new_match_length > best_match_size
            best_match_in_old = index_in_old - new_match_length + 1
            best_match_in_new = index_in_new - new_match_length + 1
            best_match_size = new_match_length
          end
        end
        match_length_at = new_match_length_at
      end

#      best_match_in_old, best_match_in_new, best_match_size = add_matching_words_left(
#          best_match_in_old, best_match_in_new, best_match_size, start_in_old, start_in_new)
#      best_match_in_old, best_match_in_new, match_size = add_matching_words_right(
#          best_match_in_old, best_match_in_new, best_match_size, end_in_old, end_in_new)

      return (best_match_size != 0 ? Match.new(best_match_in_old, best_match_in_new, best_match_size) : nil)
    end

    def add_matching_words_left(match_in_old, match_in_new, match_size, start_in_old, start_in_new)
      while match_in_old > start_in_old and 
            match_in_new > start_in_new and 
            @old_words[match_in_old - 1] == @new_words[match_in_new - 1]
        match_in_old -= 1
        match_in_new -= 1
        match_size += 1
      end
      [match_in_old, match_in_new, match_size]
    end

    def add_matching_words_right(match_in_old, match_in_new, match_size, end_in_old, end_in_new)
      while match_in_old + match_size < end_in_old and 
            match_in_new + match_size < end_in_new and
            @old_words[match_in_old + match_size] == @new_words[match_in_new + match_size]
        match_size += 1
      end
      [match_in_old, match_in_new, match_size]
    end

    def explode(sequence)
      sequence.is_a?(String) ? sequence.split(//) : sequence
    end

  end # of class Diff Builder
  
end
