module Ariel   
  class TokenStream < Array
    attr_accessor :cur_pos
    DEFAULT_RE=/[[:alpha:]]+|\d+|[^\w\s]+/ #Improved from: /\w+|[^\w\s]+/ to split Item94 in to Item, 94. Probably undesirable to split hyphenated words.
    
    def initialize()
      super()
      self.cur_pos=0
    end
    
    def tokenize(input, stream_offset=nil, regex=DEFAULT_RE)
      unless stream_offset  #This handles the case where a TokenStream is built in chunks
        if self.empty?
          stream_offset=0
        else
          stream_offset=self.last.end_loc
        end
      end
      matches=[]
      input.scan(regex) { matches << Regexp.last_match } #This is unfortunate. Without RCR 276 I'm not sure what else to do.
      matches.each do |match| 
        text, start_loc, end_loc = match[0], match.offset(0)[0], match.offset(0)[1]
        self << Token.new(text, start_loc+stream_offset, end_loc+stream_offset)
      end
      return matches.length
    end
    
		def advance            #Returns current token and consumes it
      self.cur_pos+=1
      self[self.cur_pos-1]
    end
    
    def rewind
      self.cur_pos=0
    end
    
    def skip_to(*landmark_group)
      original_pos=self.cur_pos
      if self.any? {|token| token.matches?(landmark_group.first)}  #Search for first landmark
        p "Sucess"
        self.cur_pos-=1
        if landmark_group.all? {|landmark| self.advance.matches?(landmark)}
          p "Condition true"
          return self.cur_pos
        end
      end
      self.cur_pos=original_pos #No match, return TokenStream to original state
      return nil 
    end
      
    def each
      while (t = self.advance)
        yield t
      end
    end

    def current_token
      self[self.cur_pos]
    end

  end

  class LabeledStream < TokenStream
    attr_accessor :label_index
    def tokenize(input, consume_until=nil, stream_offset=nil, regex=DEFAULT_RE)
      if consume_until
        super(input[0...consume_until], stream_offset, regex) #Split the stream at the label to ensure it is tokenised seperately
        self.label_index=(self.size) #Next token will be the desired label
        super(input[consume_until..-1], stream_offset, regex)
      else
        super(input, stream_offset, regex)
      end
    end

    def reverse
      rev = super
      rev.label_index = (rev.size-(rev.label_index + 1)) unless self.label_index.nil?
      return rev
    end

    def reverse!
      self.replace(self.reverse)
    end
  end
end
