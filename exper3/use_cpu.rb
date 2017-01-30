counter = 0
loop do
  counter += 1
  puts "counter = #{counter}" if counter % 10_000_000 == 0
end
