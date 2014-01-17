module Puppet::Parser::Functions
    newfunction(:recursive_hash_merge, :type => :rvalue) do |args|
	    hash1 = args[0]
	    hash2 = args[1]
        if !hash1.is_a? Hash
            return hash2
        end
        if !hash2.is_a? Hash
            return hash1
        end
	    merged = hash1
        hash2.each do |key, value|  
            if value.is_a? Hash and !merged[key].nil?  and merged[key].is_a? Hash
                merged[key] = recursive_hash_merge(merged[key], value)
            else
                merged [key] = value;
            end
        end
        return merged
    end
end