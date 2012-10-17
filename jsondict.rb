require 'json'
require 'set'

in_file_name = ARGV[0]
out_file_name = ARGV[1] || "dictionary.json"

$dictionary = {"words"=>{}, "glosses"=>{}, "examples"=>[]}


def add_word_to_dictionary(word, gloss)
    morphemes = word.gsub(/\W+/, "").split("_")
    glossemes = gloss.gsub(/\W+/, "").split("_")
    morphemes.each do |m|
        glossemes.each do |g|
            $dictionary["words"][m] ||= [[], []] #first element of this array stores glosses; second stores indices of examples (like an inverted index)
            $dictionary["glosses"][g] ||= [[], []]
            $dictionary["words"][m][0] << g unless $dictionary["words"][m][0].include? g
            $dictionary["glosses"][g][0] << m unless $dictionary["glosses"][g][0].include? m
        end
    end
end

def index_example(example, words, glosses)
    $dictionary["examples"] << example
    index = $dictionary["examples"].length - 1
    [words, glosses].each_with_index do |list, i|
        type = (i == 0 ? "words" : "glosses")
        list.each do |word|
            morphemes = word.gsub(/\W+/, "").split("_")
            morphemes.each do |m|
                $dictionary[type][m] ||= [[], []]
                $dictionary[type][m][1] << index unless $dictionary[type][m][1].include? index
            end
        end
    end
end

if ARGV.length == 0
    puts "usage: jsondict.rb <infile> <outfile>"
    exit 1
end

#read the input file
begin
    source = File.read(in_file_name)
rescue IOError => e
    puts "Unable to read input file."
    puts e
    exit 1
end

puts source.inspect

#break input file into example groups
examples = source.split /(?:\r?\n){2,}/
examples.each_with_index do |example, i|
    examples[i] = lines = example.split /\r?\n/
    lines.each_with_index do |line, k|
        lines[k] = line.split /\s+/
    end
    
    #map words to glosses
    
    if lines.length >= 2
        words = lines[0]
        glosses = lines[1]
        if words.length != glosses.length
            puts "mismatched words glosses in example group:"
            [lines[0], lines[1]].each do |line|
                puts line.join " "
            end
            exit 1
        end
        words.each_with_index do |word, k|
            add_word_to_dictionary(word, glosses[k])
            #index_example(example, word, false) and index_example(example, glosses[k], true) unless words.length == 1
        end
        index_example(example, lines[0], lines[1...lines.length].flatten)
        #puts "lines = #{lines}"
        #if lines.length > 2
        #    (2...lines.length).each do |k|
        #        puts "lines = #{lines}"
        #        words = lines[k]
        #        puts "lines[#{k}] = #{lines[k]}"
        #        puts "words = #{words}"
        #        words.each do |word|
        #            puts "word = #{word}"
        #            index_example(example, word, true)
        #        end
        #    end
        #end
    else
        puts "example group #{i+1} has invalid number of lines (#{lines.length}):"
        lines.each do |line|
            puts line.join " "
        end
        exit 1
    end
    
end

begin
    File.write(out_file_name, $dictionary.to_json)
    puts "Wrote file to #{out_file_name}. Done!"
rescue IOError => e
    puts "couldn't write to output file. Sad times :("
    exit 1
end

